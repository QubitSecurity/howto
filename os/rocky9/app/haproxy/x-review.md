결론부터 말씀드리면, **WAF가 실제 접속자 IP를 차단해야 한다면 HAProxy에서 “하나의 정답 IP”를 임의로 만들어 넣는 방식보다, HAProxy는 신뢰 경계에 맞게 XFF 체인을 정규화하고 WAF가 `trusted proxy list` 기준으로 실제 차단 IP를 선택하는 방식이 가장 적합합니다.**

즉, 일반화된 정답은 이것입니다.

```text
1. HAProxy에 직접 접속한 IP가 신뢰 프록시가 아니면
   → 기존 XFF는 모두 버리고
   → X-Forwarded-For = %[src]

2. HAProxy에 직접 접속한 IP가 신뢰 프록시이면
   → 기존 XFF 체인은 보존하고
   → HAProxy가 본 직전 홉 %[src]를 XFF 뒤에 추가

3. WAF는 XFF를 왼쪽부터 믿으면 안 되고
   → 오른쪽부터 trusted proxy를 건너뛰고
   → 처음 만나는 non-trusted IP를 차단 대상 IP로 사용
```

이 방식이 필요한 이유는 XFF는 여러 프록시를 거치면 `<client>, <proxy1>, ..., <proxyN>` 형태가 되고, 오른쪽 값일수록 HAProxy에 가까운 최근 프록시입니다. MDN도 보안 용도에서는 신뢰 프록시 목록을 두고 오른쪽에서 왼쪽으로 검색하면서 신뢰 프록시를 건너뛴 뒤 처음 만나는 IP를 사용해야 한다고 설명합니다. ([MDN 웹 문서][1])

---

## 권장 HAProxy XFF 설정

아래 설정을 WAF 앞단 HAProxy의 `frontend`에 넣는 것을 권장합니다.

```haproxy
#---------------------------------------------------------------------
# WAF 전달용 X-Forwarded-For 정규화 정책
#
# 목적:
#   - 직접 접속자가 조작한 XFF는 신뢰하지 않음
#   - CDN / Squid / L4 / Reverse Proxy 등 신뢰 프록시가 전달한 XFF는 보존
#   - HAProxy가 직접 관측한 직전 홉 src를 XFF 체인 뒤에 추가
#   - WAF는 오른쪽부터 trusted proxy를 건너뛰며 실제 차단 IP 결정
#---------------------------------------------------------------------

frontend fe_https
    bind 203.0.113.100:443 ssl crt /etc/haproxy/certs/site.pem alpn h2,http/1.1
    mode http

    #-------------------------------------------------------------
    # HAProxy에 직접 접속할 수 있는 신뢰 프록시 목록
    # CDN, Squid, L4, WAF 앞단 Proxy의 egress IP/CIDR만 등록
    # 일반 사용자 대역 또는 0.0.0.0/0 등록 금지
    #-------------------------------------------------------------
    acl from_trusted_upstream src -f /etc/haproxy/trusted_upstreams.lst

    # XFF 존재 여부
    # req.fhdr_cnt는 comma 기준으로 쪼개지 않고 header occurrence 개수를 봄
    acl has_xff req.fhdr_cnt(X-Forwarded-For) gt 0

    #-------------------------------------------------------------
    # 포렌식/로그용 원본 헤더 캡처
    # 필요 없으면 제거 가능
    #-------------------------------------------------------------
    http-request capture req.hdrs len 4096

    #-------------------------------------------------------------
    # WAF가 다른 IP 헤더를 잘못 신뢰하지 않도록 제거
    # WAF는 X-Forwarded-For만 신뢰하도록 구성하는 것을 권장
    #-------------------------------------------------------------
    http-request del-header Forwarded
    http-request del-header X-Real-IP
    http-request del-header X-Client-IP
    http-request del-header True-Client-IP
    http-request del-header CF-Connecting-IP
    http-request del-header Fastly-Client-IP

    #-------------------------------------------------------------
    # Case 1.
    # HAProxy에 직접 접속한 IP가 신뢰 프록시가 아닌 경우
    #
    # 예:
    #   External User -> HAProxy -> WAF
    #
    # 이 경우 사용자가 보낸 XFF는 모두 조작 가능하므로 제거
    # WAF에는 HAProxy가 실제 TCP 연결에서 본 src만 전달
    #-------------------------------------------------------------
    http-request del-header X-Forwarded-For if !from_trusted_upstream
    http-request set-header X-Forwarded-For %[src] if !from_trusted_upstream

    #-------------------------------------------------------------
    # Case 2.
    # HAProxy에 직접 접속한 IP가 신뢰 프록시인데 XFF가 없는 경우
    #
    # WAF가 실제 접속자 IP를 차단해야 한다면,
    # trusted upstream이 XFF를 주지 않는 것은 구성 오류로 보는 것이 안전
    # 운영 정책상 health check 예외가 필요하면 별도 ACL로 제외
    #-------------------------------------------------------------
    http-request deny deny_status 400 if from_trusted_upstream !has_xff

    #-------------------------------------------------------------
    # Case 3.
    # HAProxy에 직접 접속한 IP가 신뢰 프록시이고 XFF가 있는 경우
    #
    # 기존 XFF 체인을 보존하고,
    # HAProxy가 직접 관측한 직전 홉 src를 XFF 뒤에 추가
    #
    # 이때 WAF는 multiple XFF header를 하나의 XFF list로 합쳐서
    # 오른쪽부터 trusted proxy를 건너뛰어야 함
    #-------------------------------------------------------------
    http-request add-header X-Forwarded-For %[src] if from_trusted_upstream has_xff

    # 일반 전달 헤더
    http-request set-header X-Forwarded-Proto https
    http-request set-header X-Forwarded-Port 443
    http-request set-header X-Forwarded-Host %[req.hdr(Host)]

    default_backend be_waf
```

---

## `/etc/haproxy/trusted_upstreams.lst`

이 파일에는 **HAProxy에 직접 접속할 수 있는 신뢰 프록시의 IP/CIDR만** 넣습니다.

```text
# /etc/haproxy/trusted_upstreams.lst
#
# 예시 IP입니다. 실제 운영 IP/CIDR로 교체하세요.
# CDN egress IP
# Squid egress IP
# L4 SNAT IP
# 앞단 Reverse Proxy IP

192.0.2.10
192.0.2.20
198.51.100.0/24
203.0.113.0/24
```

절대 아래처럼 넣으면 안 됩니다.

```text
0.0.0.0/0
::/0
```

이렇게 넣으면 모든 사용자가 “신뢰 프록시”가 되어 XFF 조작을 막을 수 없습니다.

---

## WAF가 반드시 해야 하는 해석 방식

WAF는 다음 방식으로 실제 차단 IP를 계산해야 합니다.

```text
1. HAProxy에서 온 요청만 신뢰한다.
2. X-Forwarded-For 전체 목록을 만든다.
3. 여러 개의 X-Forwarded-For 헤더가 있으면 하나의 목록으로 합친다.
4. 오른쪽에서 왼쪽으로 읽는다.
5. trusted proxy 목록에 있는 IP는 건너뛴다.
6. 처음 만나는 non-trusted IP를 차단 대상 IP로 사용한다.
```

예를 들어 WAF가 아래 XFF를 받았다고 가정합니다.

```http
X-Forwarded-For: 1.1.1.1, 198.51.100.10, 192.0.2.20
X-Forwarded-For: 192.0.2.30
```

그리고 trusted proxy 목록이 다음과 같다면:

```text
192.0.2.20
192.0.2.30
```

WAF는 오른쪽부터 봅니다.

```text
192.0.2.30  -> trusted proxy, skip
192.0.2.20  -> trusted proxy, skip
198.51.100.10 -> non-trusted, 차단 대상
1.1.1.1 -> 공격자가 조작했을 수 있으므로 사용하지 않음
```

따라서 WAF의 차단 대상은 다음입니다.

```text
198.51.100.10
```

MDN도 여러 개의 XFF 헤더가 있을 수 있으므로 전체 값을 하나의 목록으로 합쳐야 하며, 여러 헤더 중 하나만 사용하는 것은 충분하지 않다고 설명합니다. 또한 보안 용도에서는 trusted proxy count 또는 trusted proxy list 방식으로 신뢰 가능한 주소를 선택해야 한다고 설명합니다. ([MDN 웹 문서][1])

---

## WAF가 Nginx 기반이라면 예시

WAF가 Nginx 또는 Nginx 기반 모듈 앞에서 동작한다면 다음 구조가 안전합니다.

```nginx
# HAProxy가 WAF에 접속하는 IP
set_real_ip_from 10.100.20.1;
set_real_ip_from 10.100.20.2;

# HAProxy 앞단의 신뢰 프록시/CDN/Squid/L4 대역
# 실제 운영 대역으로 교체
set_real_ip_from 192.0.2.10;
set_real_ip_from 192.0.2.20;
set_real_ip_from 198.51.100.0/24;
set_real_ip_from 203.0.113.0/24;

real_ip_header X-Forwarded-For;
real_ip_recursive on;
```

Nginx 공식 문서 기준으로 `real_ip_recursive on`이면 신뢰 주소와 일치하는 원래 클라이언트 주소를 XFF의 **마지막 non-trusted 주소**로 대체합니다. 즉, WAF/Nginx가 오른쪽에서 왼쪽으로 trusted proxy를 건너뛰는 방식과 같은 방향입니다. ([Nginx][2])

---

## 왜 `req.hdr()` 방식은 부적합한가

아래 방식은 WAF에 정확한 IP 체인을 전달하는 일반화 설정으로는 부적합합니다.

```haproxy
http-request set-header X-Forwarded-For %[src],%[req.hdr(X-Forwarded-For)] if { req.hdr(X-Forwarded-For) -m found }
```

HAProxy 문서에서 `req.hdr()`는 해당 헤더의 마지막 comma-separated 값을 반환합니다. XFF 전체 체인이 아니라 마지막 값만 가져올 수 있으므로, 다중 프록시 환경이나 사용자가 임의 XFF를 여러 개 넣은 테스트에서 전체 경로를 보존하지 못합니다. ([HAProxy Documentation][3])

첨부 테스트에서도 `req.hdr` 방식은 curl로 임의 XFF를 넣어도 결과가 `172.16.10.200,172.16.18.253`처럼 제한적으로 남았습니다. 즉, 이 방식은 “체인 보존”이 아니라 “일부 값만 남기는 방식”입니다. 

---

## 왜 `req.fhdr()` 단독 방식도 일반화하기 어렵나

아래 방식도 조건부로만 동작합니다.

```haproxy
http-request set-header X-Forwarded-For %[src],%[req.fhdr(X-Forwarded-For)] if { req.fhdr(X-Forwarded-For) -m found }
```

`req.fhdr()`는 comma를 구분자로 쪼개지 않고 full value를 반환한다는 장점이 있지만, HAProxy 문서 기준으로는 **마지막 header occurrence의 full value**를 반환합니다. 즉, 여러 개의 `X-Forwarded-For` 헤더 라인이 그대로 HAProxy까지 들어오면 모든 occurrence를 자동으로 합친다고 보장할 수 없습니다. ([HAProxy Documentation][3])

첨부 테스트에서도 Squid 경유 구조에서는 `req.fhdr`가 더 많은 XFF 값을 보여주었지만, direct 구조에서는 마지막 XFF 헤더만 확인되는 문제가 나타났습니다.  

따라서 WAF용 일반화 설정에서는 `req.fhdr()`로 HAProxy가 단일 XFF 문자열을 만들어주는 방식보다, **기존 XFF를 보존하고 HAProxy가 본 src를 새 XFF occurrence로 추가한 뒤 WAF가 전체 XFF 목록을 해석하는 방식**이 더 안전합니다.

---

## `set-header`가 아니라 `add-header`를 쓰는 이유

신뢰 프록시에서 온 요청의 경우에는 기존 XFF 체인을 보존해야 합니다. 이때 `set-header`는 기존 헤더를 제거하고 새 값으로 대체합니다. HAProxy 공식 문서도 `set-header`는 기존 헤더를 먼저 제거한다고 설명합니다. ([HAProxy Documentation][3])

반대로 `add-header`는 기존 HTTP 헤더 필드 뒤에 새 헤더를 추가합니다. 따라서 trusted upstream이 이미 만든 XFF 체인을 유지하면서 HAProxy가 직접 관측한 `%[src]`를 추가하려면 `add-header`가 적합합니다. ([HAProxy Documentation][3])

HAProxy의 `option forwardfor`도 XFF를 추가하는 기능이지만, 이번 경우처럼 “신뢰 프록시에서 온 요청인지 여부”에 따라 기존 XFF를 버리거나 보존해야 하므로, 명시적으로 `acl from_trusted_upstream`과 `http-request add-header/set-header/del-header`를 조합하는 편이 더 안전합니다. HAProxy 문서도 `option forwardfor if-none`은 헤더가 최종 사용자 통제하에 있을 수 있으면 보안 문제가 될 수 있어 완전히 신뢰된 환경에서만 사용하라고 설명합니다. ([HAProxy Documentation][3])

---

## 최종 권장 구조

WAF가 실제 접속자 IP를 차단해야 한다면 다음 조합이 가장 적합합니다.

```text
HAProxy:
- trusted_upstreams.lst 운영
- 비신뢰 src 요청은 기존 XFF 삭제 후 XFF=%[src]
- 신뢰 src 요청은 기존 XFF 보존 후 XFF 뒤에 %[src] 추가
- X-Real-IP, X-Client-IP, True-Client-IP 등 혼동 가능한 헤더 삭제
- WAF에는 X-Forwarded-For만 기준으로 전달

WAF:
- HAProxy IP를 trusted proxy로 등록
- HAProxy 앞단 CDN/Squid/L4/Proxy 대역도 trusted proxy로 등록
- XFF 전체 목록을 오른쪽부터 검색
- trusted proxy는 건너뛰고 첫 non-trusted IP를 차단
- leftmost XFF를 무조건 신뢰하지 않음
```

중요한 제한도 있습니다. **어떤 환경에서든 HAProxy만으로 “진짜 공격자 IP”를 100% 알 수는 없습니다.** 앞단 CDN/Squid/Proxy가 실제 클라이언트 IP를 XFF 또는 PROXY protocol 등으로 정확히 전달해야 하고, 그 앞단 장비가 신뢰 프록시 목록에 있어야 합니다. 신뢰할 수 없는 중간 프록시 뒤의 사용자는 기술적으로 그 중간 프록시 IP까지만 보안 식별자로 사용할 수 있습니다. MDN도 보안 용도에서 선택된 첫 번째 신뢰 가능한 XFF IP가 실제 최종 사용자 단말이 아니라 신뢰되지 않은 중간 프록시일 수 있지만, 보안 판단에 사용할 수 있는 유일한 IP라고 설명합니다. ([MDN 웹 문서][1])

[1]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/X-Forwarded-For "X-Forwarded-For header - HTTP | MDN"
[2]: https://nginx.org/en/docs/http/ngx_http_realip_module.html?utm_source=chatgpt.com "Module ngx_http_realip_module"
[3]: https://docs.haproxy.org/2.8/configuration.html "HAProxy version 2.8.25 - Configuration Manual"
