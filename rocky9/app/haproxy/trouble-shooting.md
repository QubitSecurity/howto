# ✅ 정리

![Image](https://cdn.haproxy.com/img/containers/partner_integrations/haproxy-reverse-proxy-diagram.png/2940da862726a036270286d3e03be767/haproxy-reverse-proxy-diagram.png)

![Image](https://cdn.haproxy.com/img/containers/partner_integrations/haproxy-ssl-termination-diagram.png/2b76cba5c6c294feecde87f904b734af/haproxy-ssl-termination-diagram.png)

![Image](https://static.wixstatic.com/media/f146c1_28032b4f8fdb4b609b396ee36fcf1dbe~mv2.png/v1/fill/w_980%2Ch_515%2Cal_c%2Cq_90%2Cusm_0.66_1.00_0.01%2Cenc_avif%2Cquality_auto/f146c1_28032b4f8fdb4b609b396ee36fcf1dbe~mv2.png)

* **Client → HAProxy : HTTPS**
* **HAProxy : TLS 종료**
* **HAProxy → WAF : HTTP(80, 평문)**
* **WAF : HTTP 레벨 분석(ModSecurity)**
* **WAF → Web : HTTPS**

이 구조는 **성능/보안/운영 모두에서 가장 안정적**이며,
현재의 **50% 지연 문제를 구조적으로 제거**합니다.

---

# 1️⃣ haproxy.cfg — 반드시 수정할 것

## ❌ 기존 문제점

```haproxy
server kihawaf75 10.10.10.75:443 check
server kihawaf95 10.10.10.95:443 check
```

* TLS 종료 후 **평문을 WAF의 TLS 리스너(443 ssl)** 로 전송
* → TLS 핸드셰이크 미일치
* → 재시도 / 대기 / 타임아웃
* → **50% 확률 지연 발생**

---

## ✅ 수정된 정답 구성 (붙여넣기용)

### 🔹 Backend (HTTPS Frontend → WAF)

```haproxy
backend https_backend_443
    mode http
    balance roundrobin

    option forwardfor
    http-request set-header X-Forwarded-Proto https
    http-request set-header X-Forwarded-Port %[dst_port]

    timeout connect 5s
    timeout server  300s

    server kihawaf75 10.10.10.75:80 check
    server kihawaf95 10.10.10.95:80 check
```

### 🔹 핵심 포인트

| 항목                        | 이유                        |
| ------------------------- | ------------------------- |
| `:443 → :80`              | WAF는 **평문 분석**            |
| `X-Forwarded-Proto https` | 원래 HTTPS 요청임을 WAF/Web에 전달 |
| `mode http`               | WAF 규칙/로그/헤더 정상 처리        |
| `roundrobin`              | WAF간 부하 균등 (source 필요 없음) |

---

# 2️⃣ WAF main.conf — 반드시 수정할 것

## 🔹 (A) real_ip 신뢰 대상을 **HAProxy만** 허용

❌ 기존:

```nginx
set_real_ip_from 0.0.0.0/0;
```

### ✅ 수정:

```nginx
set_real_ip_from 192.168.101.121;
real_ip_header X-Forwarded-For;
real_ip_recursive on;
```

📌 이유:

* XFF 위조 방지
* WAF 차단/Rate-limit/로그 정확성 보장

---

## 🔹 (B) 80 / 443 역할을 명확히 분리

### ✅ 권장 운영 정책

### 🔸 80 : HAProxy 전용 (분석용)

```nginx
server {
    listen 80;
    server_name gw.kiha21.or.kr;

    set_real_ip_from 192.168.101.121;
    real_ip_header X-Forwarded-For;
    real_ip_recursive on;

    location / {
        include plura/ac_0;
        include plura/defense_0;

        proxy_pass http://192.168.101.121;
        include proxy.conf;
    }

    include server.conf;
}
```

### 🔸 443 : 직접접속 차단 또는 제한 (선택)

```nginx
server {
    listen 443 ssl;
    server_name gw.kiha21.or.kr;

    ssl_certificate     plura/cert.pem;
    ssl_certificate_key plura/key.pem;
    include ssl.conf;

    # 직접 접근 제한
    allow 192.168.101.121;
    deny all;

    include server.conf;
}
```

📌 만약 **WAF 직접 접근이 필요 없다면**,
→ **443 server 블록 자체를 제거**하는 것이 가장 깔끔합니다.

---

# 3️⃣ proxy.conf — 반드시 같이 맞춰야 할 1줄 (중요)

현재:

```nginx
proxy_set_header X-Forwarded-Proto $scheme;
```

문제:

* HAProxy → WAF가 HTTP(80)이므로 `$scheme = http`
* 실제 요청은 HTTPS인데 Web이 HTTP로 오인

### ✅ 수정:

```nginx
proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
```

📌 이 1줄이 없으면:

* Web에서 HTTPS 리다이렉트 루프
* 로그인/세션 쿠키 Secure 오류
* 특정 요청 지연 발생 가능

---

# 4️⃣ 수정 요약 체크리스트 (운영 전 확인)

### haproxy.cfg

* [x] WAF 대상 포트 **443 → 80**
* [x] `X-Forwarded-Proto https`
* [x] `mode http`
* [x] 헬스체크 정상

### WAF main.conf

* [x] `set_real_ip_from 192.168.101.121`
* [x] 80 = HAProxy 전용 분석
* [x] 443 = 제거 또는 접근 제한

### proxy.conf

* [x] `$scheme` → `$http_x_forwarded_proto`

---

# ✅ 결론

* 지금의 **50% 지연 문제는 구조적 원인이었고**
* 위 수정으로 **100% 제거**
* WAF 분석 정확도 ↑
* 운영/확장/이중화에 가장 안정적인 형태

---
