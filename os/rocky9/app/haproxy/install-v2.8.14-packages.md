# HAProxy 2.8.14 패키지 설치 가이드

- 문서명: `install-v2.8.14-packages.md`
- 대상 OS: Rocky Linux 9
- 설치 방식: OS 패키지 설치, `dnf install haproxy`
- 대상 버전: HAProxy 2.8.14 패키지 기준
- 작성 목적:
  - Rocky Linux 9에서 HAProxy를 패키지로 설치한다.
  - 외부 사용자가 조작한 `X-Forwarded-For`를 신뢰하지 않도록 구성한다.
  - TLS 1.2 이상만 허용하고, TLS 1.2에서는 강화된 Cipher만 사용한다.
  - Keepalived VIP 환경에서 HAProxy가 안정적으로 기동되도록 구성한다.

> 이 문서는 외부 사용자가 HAProxy VIP로 직접 접속하는 구성을 기본 전제로 합니다.  
> HAProxy 앞단에 CDN, L4, WAF, Proxy가 있는 경우에는 `X-Forwarded-For` 처리 정책을 별도로 조정해야 합니다.

> 이 문서의 공인 IP는 실제 운영 IP가 아니라 문서 예시용 IP를 사용합니다.  
> 예시 VIP: `203.0.113.100`  
> 예시 차단/공격자 IP: `198.51.100.10`  
> 실제 운영 시에는 고객사에 할당된 실제 공인 VIP와 실제 차단 대상 IP로 변경해야 합니다.

---

## 1. 구성 기준

| 구분 | 값 |
|---|---|
| OS | Rocky Linux 9 |
| HAProxy 설치 방식 | `dnf install haproxy` |
| HAProxy 버전 | 2.8.14 패키지 기준 |
| VIP 예시 | `203.0.113.100` |
| HTTP Listen 예시 | `203.0.113.100:80` |
| HTTPS Listen 예시 | `203.0.113.100:443` |
| 내부 웹서버 1 | `10.100.21.100:80` |
| 내부 웹서버 2 | `10.100.21.101:80` |
| 인증서 PEM | `/etc/haproxy/certs/site.pem` |
| 차단 IP 파일 | `/etc/haproxy/blocked_ips.lst` |
| Stats 페이지 | `127.0.0.1:8888/stats` |

---

## 2. 핵심 보안 정책

### 2.1 X-Forwarded-For 조작 방지

외부 사용자가 임의로 아래와 같은 헤더를 넣어 요청할 수 있습니다.

```http
X-Forwarded-For: 198.51.100.10
```

이 값을 백엔드 웹서버, WAF, 애플리케이션, 로그 분석기가 신뢰하면 IP 차단 우회가 발생할 수 있습니다.

따라서 이 문서에서는 다음 정책을 사용합니다.

1. 외부 사용자가 `X-Forwarded-For`를 직접 보내면 `400 Bad Request`로 차단한다.
2. IP 차단 판단은 `X-Forwarded-For`가 아니라 HAProxy가 실제 TCP 연결에서 관측한 `src` 기준으로 수행한다.
3. 백엔드로 전달하는 `X-Forwarded-For`는 HAProxy가 직접 생성한다.
4. `option forwardfor`는 사용하지 않는다.

### 2.2 TLS 정책

기본 TLS 정책은 다음과 같습니다.

1. TLS 1.0 차단
2. TLS 1.1 차단
3. TLS 1.2 허용
4. TLS 1.3 허용
5. TLS 1.2에서는 ECDHE + AEAD 계열 Cipher만 허용
6. TLS 1.3 CipherSuite는 별도 지정

> 고객 정책상 TLS 1.2만 허용하고 TLS 1.3도 차단해야 한다면 `ssl-default-bind-options`에 `ssl-max-ver TLSv1.2`를 추가할 수 있습니다.  
> 일반적으로는 TLS 1.3도 함께 허용하는 것이 권장됩니다.

---

## 3. root 권한 전환

```bash
sudo -i
```

이후 명령은 root 권한 기준으로 실행합니다.

---

## 4. 시스템 설정

### 4.1 파일 핸들 제한 설정

기존 메모에는 `/etc/security/limits.conf` 수정 방식이 포함되어 있습니다.

```bash
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf
echo "* soft nproc 131072" >> /etc/security/limits.conf
echo "* hard nproc 131072" >> /etc/security/limits.conf
cat /etc/security/limits.conf
```

다만 systemd로 실행되는 HAProxy 서비스에는 `/etc/security/limits.conf`만으로 충분하지 않을 수 있습니다.  
HAProxy 서비스에는 systemd override를 함께 적용하는 것이 좋습니다.

```bash
systemctl edit haproxy
```

아래 내용을 입력합니다.

```ini
[Service]
LimitNOFILE=65536
LimitNPROC=131072
```

반영합니다.

```bash
systemctl daemon-reload
```

---

## 5. Keepalived VIP 바인딩용 커널 설정

Keepalived 환경에서는 백업 서버가 아직 VIP를 보유하지 않은 상태에서도 HAProxy가 먼저 기동되어야 합니다.

두 서버 모두에서 아래 설정을 적용합니다.

```bash
cat <<'EOF' > /etc/sysctl.d/99-haproxy-vip.conf
net.ipv4.ip_nonlocal_bind = 1
EOF

sysctl --system
```

확인합니다.

```bash
sysctl net.ipv4.ip_nonlocal_bind
```

정상 출력은 다음과 같습니다.

```text
net.ipv4.ip_nonlocal_bind = 1
```

이 설정이 없으면 BACKUP 서버에서 HAProxy가 다음과 같은 오류로 기동하지 못할 수 있습니다.

```text
cannot bind socket [203.0.113.100:443]
```

---

## 6. PLURA 에이전트 설치

PLURA 로그 수집 또는 보안 관제 연동이 필요한 경우에만 설치합니다.

```bash
curl https://repo.plura.io/v6/agent/install.sh | bash
```

> 운영 서버에서 원격 스크립트를 실행할 때는 사내 표준 절차에 따라 스크립트 출처와 내용을 확인한 후 실행하는 것이 좋습니다.

---

## 7. HAProxy 패키지 설치

```bash
dnf update -y
dnf install haproxy -y
```

버전을 확인합니다.

```bash
haproxy -v
```

예상 출력 형태는 다음과 같습니다.

```text
HAProxy version 2.8.14 ...
```

상세 빌드 옵션을 확인합니다.

```bash
haproxy -vv | egrep 'HAProxy version|OpenSSL|PCRE|PCRE2|ZLIB|SYSTEMD'
```

---

## 8. 디렉터리 생성

```bash
mkdir -p /etc/haproxy/certs
touch /etc/haproxy/blocked_ips.lst

chown root:root /etc/haproxy/blocked_ips.lst
chmod 644 /etc/haproxy/blocked_ips.lst
```

차단 IP를 추가하려면 다음처럼 입력합니다.

```bash
echo "198.51.100.10" >> /etc/haproxy/blocked_ips.lst
```

---

## 9. 인증서 개인키 암호 해제

HAProxy는 서비스 재시작 시 암호 입력이 불가능하므로, 인증서 개인키에 암호가 걸려 있으면 암호를 해제한 키를 사용해야 합니다.

먼저 키 형식을 확인합니다.

```bash
openssl pkey -in server.key -text -noout
```

RSA 키라면 다음 명령을 사용할 수 있습니다.

```bash
openssl rsa -in server.key -out server_nopass.key
```

범용 방식은 다음입니다.

```bash
openssl pkey -in server.key -out server_nopass.key
```

권한을 제한합니다.

```bash
chmod 600 server_nopass.key
```

인증서 체인과 개인키를 하나의 PEM 파일로 합칩니다.

```bash
cat fullchain.pem server_nopass.key > /etc/haproxy/certs/site.pem

chown root:root /etc/haproxy/certs/site.pem
chmod 600 /etc/haproxy/certs/site.pem
```

파일 구성은 다음 순서를 권장합니다.

```text
-----BEGIN CERTIFICATE-----
서버 인증서
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
중간 인증서
-----END CERTIFICATE-----
-----BEGIN PRIVATE KEY-----
개인키
-----END PRIVATE KEY-----
```

---

## 10. 방화벽 설정

기본 HTTP와 HTTPS를 허용합니다.

```bash
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
```

Stats 페이지를 외부에서 직접 열어야 하는 경우에만 `8888/tcp`를 추가합니다.

```bash
firewall-cmd --permanent --add-port=8888/tcp
firewall-cmd --reload
```

> 이 문서의 기본 설정은 Stats 페이지를 `127.0.0.1:8888`에만 바인딩합니다.  
> 이 경우 외부 방화벽에 `8888/tcp`를 열 필요가 없습니다.  
> 외부 관리망에서 Stats 페이지를 보려면 반드시 접근 ACL 또는 방화벽으로 관리 IP만 허용해야 합니다.

---

## 11. HAProxy 설정 파일

기존 설정을 백업합니다.

```bash
cp -a /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak.$(date +%Y%m%d%H%M%S)
```

`/etc/haproxy/haproxy.cfg` 파일을 아래 내용으로 작성합니다.

```haproxy
#---------------------------------------------------------------------
# HAProxy 2.8.14 package configuration
# Rocky Linux 9
#
# Security goals:
#   1) X-Forwarded-For spoofing protection
#   2) TLS 1.2+ with strong ciphers only
#---------------------------------------------------------------------

global
    log stdout format raw local0 info

    user haproxy
    group haproxy

    maxconn 50000

    # systemd 환경에서 master-worker 방식 사용
    master-worker

    #-----------------------------------------------------------------
    # TLS security baseline
    # - TLS 1.2 이상만 허용
    # - TLS 1.2 Cipher는 ECDHE + AEAD 계열만 허용
    # - TLS 1.3 CipherSuite는 별도 지정
    #-----------------------------------------------------------------
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

    # TLS 1.2 이하용 Cipher
    ssl-default-bind-ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305

    # TLS 1.3용 CipherSuite
    ssl-default-bind-ciphersuites TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256

    ssl-default-bind-curves X25519:secp256r1:secp384r1
    tune.ssl.default-dh-param 2048

defaults
    mode http
    log global

    option httplog
    option dontlognull
    option http-buffer-request

    timeout http-request 10s
    timeout connect 5s
    timeout client 60s
    timeout server 60s
    timeout http-keep-alive 10s
    timeout check 5s

    retries 3

#---------------------------------------------------------------------
# HTTP frontend
# 80 포트는 HTTPS로 리다이렉트
#---------------------------------------------------------------------
frontend fe_http
    bind 203.0.113.100:80
    mode http

    http-request redirect scheme https code 301

#---------------------------------------------------------------------
# HTTPS frontend
# 외부 사용자는 VIP 203.0.113.100:443 으로 접속
#---------------------------------------------------------------------
frontend fe_https
    bind 203.0.113.100:443 ssl crt /etc/haproxy/certs/site.pem alpn h2,http/1.1
    mode http

    #-------------------------------------------------------------
    # XFF 조작 시도 로깅용 캡처
    # set-header 또는 deny 이전에 수행
    #-------------------------------------------------------------
    http-request capture req.hdr(X-Forwarded-For) len 128

    #-------------------------------------------------------------
    # 1. X-Forwarded-For 조작 요청 차단
    #
    # 외부 사용자가 직접 HAProxy에 접속하는 구조에서는
    # 클라이언트가 보낸 XFF를 신뢰하면 안 됩니다.
    #-------------------------------------------------------------
    acl has_xff req.hdr(X-Forwarded-For) -m found
    http-request deny deny_status 400 if has_xff

    #-------------------------------------------------------------
    # 2. IP 차단은 XFF가 아니라 실제 접속 IP 기준
    #
    # src = HAProxy가 TCP 연결에서 직접 관측한 원본 IP
    #-------------------------------------------------------------
    acl blocked_src src -f /etc/haproxy/blocked_ips.lst
    http-request deny deny_status 403 if blocked_src

    #-------------------------------------------------------------
    # 3. 백엔드로 전달할 XFF는 HAProxy가 직접 생성
    #
    # set-header는 기존 헤더를 제거하고 새 값으로 설정합니다.
    # 따라서 사용자가 조작한 XFF가 백엔드로 전달되지 않습니다.
    #-------------------------------------------------------------
    http-request del-header Forwarded
    http-request set-header X-Forwarded-For %[src]
    http-request set-header X-Real-IP %[src]
    http-request set-header X-Forwarded-Proto https
    http-request set-header X-Forwarded-Port 443
    http-request set-header X-Forwarded-Host %[req.hdr(Host)]

    default_backend be_web

#---------------------------------------------------------------------
# Backend web servers
# 내부 웹서버와는 eth1 내부망으로 통신
#---------------------------------------------------------------------
backend be_web
    mode http
    balance roundrobin

    option httpchk GET /
    http-check expect rstatus ^(2|3)[0-9][0-9]$

    default-server inter 3s fall 3 rise 2

    server web1 10.100.21.100:80 check
    server web2 10.100.21.101:80 check

#---------------------------------------------------------------------
# Local stats page
# 외부 공개 금지
# SSH 터널 또는 로컬 접속으로만 확인 권장
#---------------------------------------------------------------------
frontend fe_stats
    bind 127.0.0.1:8888
    mode http

    stats enable
    stats uri /stats
    stats refresh 10s
    stats auth admin:CHANGE_ME_STRONG_PASSWORD
```

---

## 12. 설정 검사

```bash
haproxy -c -f /etc/haproxy/haproxy.cfg
```

정상 출력은 다음과 같습니다.

```text
Configuration file is valid
```

오류가 있으면 HAProxy를 재시작하지 말고 설정 파일을 먼저 수정합니다.

---

## 13. 서비스 시작 및 자동 실행

```bash
systemctl enable --now haproxy
systemctl restart haproxy
systemctl status haproxy
```

로그 확인:

```bash
journalctl -u haproxy -f
```

---

## 14. TLS 테스트

TLS 1.0은 실패해야 합니다.

```bash
openssl s_client -connect 203.0.113.100:443 -tls1
```

TLS 1.1은 실패해야 합니다.

```bash
openssl s_client -connect 203.0.113.100:443 -tls1_1
```

TLS 1.2는 성공해야 합니다.

```bash
openssl s_client -connect 203.0.113.100:443 -tls1_2
```

TLS 1.3은 지원 환경이면 성공해야 합니다.

```bash
openssl s_client -connect 203.0.113.100:443 -tls1_3
```

TLS 1.2 Cipher 확인 예시는 다음과 같습니다.

```bash
openssl s_client -connect 203.0.113.100:443 -tls1_2 -cipher 'ECDHE+AESGCM'
```

---

## 15. XFF 조작 방지 테스트

공격자가 XFF를 임의로 넣는 요청입니다.

```bash
curl -k -i -H "X-Forwarded-For: 198.51.100.10" https://203.0.113.100/
```

정상 결과는 `400` 차단입니다.

```text
HTTP/1.1 400 Bad Request
```

일반 요청은 정상 처리되어야 합니다.

```bash
curl -k -i https://203.0.113.100/
```

차단 IP 테스트는 다음과 같이 수행합니다.

```bash
echo "테스트_클라이언트_IP" >> /etc/haproxy/blocked_ips.lst
systemctl reload haproxy
```

이후 해당 IP에서 접속하면 `403`으로 차단되어야 합니다.

---

## 16. 백엔드 웹서버 설정 주의사항

백엔드 웹서버가 Nginx라면 HAProxy에서 전달한 XFF만 신뢰해야 합니다.

예시:

```nginx
set_real_ip_from 10.100.20.1;
set_real_ip_from 10.100.20.2;
real_ip_header X-Forwarded-For;
real_ip_recursive off;
```

다음 설정은 사용하면 안 됩니다.

```nginx
set_real_ip_from 0.0.0.0/0;
```

모든 출처의 XFF를 신뢰하면 HAProxy에서 방어하더라도 다른 경로를 통한 XFF 조작 위험이 다시 생깁니다.

---

## 17. 앞단 프록시가 있는 경우의 예외

이 문서의 기본 정책은 다음 구조입니다.

```text
External User -> HAProxy -> Web Server
```

만약 앞단에 CDN, L4, WAF, Proxy가 있다면 구조가 달라집니다.

```text
External User -> CDN/WAF/Proxy -> HAProxy -> Web Server
```

이 경우 CDN/WAF/Proxy가 넣어주는 `X-Forwarded-For`는 정상 헤더일 수 있습니다.  
그때는 무조건 `has_xff`를 차단하면 정상 트래픽이 차단됩니다.

앞단 프록시가 있는 경우에는 다음 중 하나로 정책을 바꾸어야 합니다.

### 17.1 단순 덮어쓰기 방식

```haproxy
http-request del-header Forwarded
http-request set-header X-Forwarded-For %[src]
http-request set-header X-Real-IP %[src]
```

이 방식은 앞단 프록시의 IP가 최종 사용자 IP로 기록됩니다.

### 17.2 신뢰 프록시 대역만 XFF 허용

```haproxy
acl trusted_proxy src 10.10.10.0/24
acl has_xff req.hdr(X-Forwarded-For) -m found

http-request deny deny_status 400 if has_xff !trusted_proxy
```

신뢰할 수 있는 앞단 프록시 대역에서 온 XFF만 허용합니다.

---

## 18. 운영 점검 명령

HAProxy 버전 확인:

```bash
haproxy -v
```

설정 검사:

```bash
haproxy -c -f /etc/haproxy/haproxy.cfg
```

서비스 상태:

```bash
systemctl status haproxy
```

리스닝 포트 확인:

```bash
ss -lntp | grep haproxy
```

로그 확인:

```bash
journalctl -u haproxy -f
```

백엔드 상태 확인:

```bash
curl -k https://203.0.113.100/
```

Stats 페이지 확인:

```bash
curl -u admin:CHANGE_ME_STRONG_PASSWORD http://127.0.0.1:8888/stats
```

---

## 19. 롤백

문제가 발생하면 백업 설정으로 되돌립니다.

```bash
ls -al /etc/haproxy/haproxy.cfg.bak.*

cp -a /etc/haproxy/haproxy.cfg.bak.YYYYMMDDHHMMSS /etc/haproxy/haproxy.cfg

haproxy -c -f /etc/haproxy/haproxy.cfg
systemctl restart haproxy
```

---

## 20. 최종 요약

```text
설치 방식: dnf install haproxy
대상 버전: HAProxy 2.8.14 패키지 기준
OS: Rocky Linux 9

필수 보안 기능:
1. XFF 조작 요청은 400으로 차단
2. IP 차단 기준은 XFF가 아니라 src 기준
3. 백엔드 전달 XFF는 HAProxy가 직접 생성
4. TLS 1.2 이상만 허용
5. TLS 1.2 Cipher는 ECDHE + AES-GCM / CHACHA20-POLY1305만 허용

Keepalived VIP 환경:
- net.ipv4.ip_nonlocal_bind = 1 적용
- HAProxy는 예시 VIP 203.0.113.100:80, 443에 바인딩
```

---

### 💾 Download

- [https://www.haproxy.org/download/](https://www.haproxy.org/download/)
