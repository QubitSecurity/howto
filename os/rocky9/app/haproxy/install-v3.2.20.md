# HAProxy 3.2.20 설치 가이드

> 대상 운영체제: Rocky Linux 9  
> 설치 방식: 소스 컴파일 설치  
> 목적: Keepalived VIP 환경에서 HAProxy 3.2.20을 안정적으로 운영하고, XFF 조작 방지와 TLS 1.2 이상 강한 암호화 정책을 적용한다.

---

## 1. 구성 개요

이 문서는 다음 구성을 기준으로 작성한다.

| 구분 | 값 |
|---|---|
| 운영체제 | Rocky Linux 9 |
| HAProxy 버전 | 3.2.20 |
| VIP | `211.43.190.100` |
| 서비스 포트 | `80`, `443` |
| 내부 웹서버 1 | `10.100.21.100:80` |
| 내부 웹서버 2 | `10.100.21.101:80` |
| 인증서 PEM | `/etc/haproxy/certs/site.pem` |
| 차단 IP 목록 | `/etc/haproxy/blocked_ips.lst` |

핵심 보안 정책은 다음과 같다.

1. 외부 사용자가 보낸 `X-Forwarded-For` 값을 신뢰하지 않는다.
2. HAProxy가 직접 확인한 실제 접속 IP, 즉 `%[src]` 값으로 `X-Forwarded-For`를 덮어쓴다.
3. IP 차단 판단은 `X-Forwarded-For`가 아니라 HAProxy가 관측한 실제 접속 IP인 `src` 기준으로 수행한다.
4. TLS는 TLS 1.2 이상만 허용한다.
5. TLS 1.2에서는 ECDHE + AEAD 계열의 강한 Cipher만 허용한다.
6. TLS 1.3 CipherSuite는 별도로 지정한다.

---

## 2. 사전 주의사항

### 2.1 기본 패키지 HAProxy와 경로 차이

Rocky Linux 9 기본 저장소로 설치하는 HAProxy는 일반적으로 `/usr/sbin/haproxy` 경로를 사용한다.

이 문서는 소스 컴파일 설치이므로 실행 파일 경로는 다음과 같다.

```bash
/usr/local/sbin/haproxy
```

따라서 systemd 서비스 파일에서도 `/usr/local/sbin/haproxy`를 사용한다.

### 2.2 Keepalived VIP 환경 주의사항

Keepalived 구성에서는 현재 MASTER 서버만 VIP를 실제로 보유한다.

BACKUP 서버는 평상시 VIP를 갖고 있지 않기 때문에, HAProxy가 `211.43.190.100:443`에 바인딩하려고 하면 실패할 수 있다.

이를 방지하기 위해 두 서버 모두에서 다음 커널 옵션을 활성화한다.

```bash
net.ipv4.ip_nonlocal_bind = 1
```

이 설정은 HAProxy가 현재 서버에 아직 할당되지 않은 VIP에도 미리 바인딩할 수 있게 한다.

### 2.3 XFF 처리 원칙

다음 방식은 사용하지 않는 것을 권장한다.

```haproxy
http-request set-header X-Forwarded-For %[src],%[req.hdr(X-Forwarded-For)] if { req.hdr(X-Forwarded-For) -m found }
```

이 방식은 사용자가 보낸 기존 `X-Forwarded-For` 값을 뒤에라도 보존한다.

백엔드 웹서버, WAF, 애플리케이션, 보안 로직이 XFF의 첫 번째 IP 또는 마지막 IP를 잘못 해석하면 차단 우회가 발생할 수 있다.

권장 방식은 다음과 같다.

```haproxy
http-request set-header X-Forwarded-For %[src]
```

이 설정은 기존 XFF를 제거하고 HAProxy가 직접 확인한 실제 접속 IP로 덮어쓴다.

---

## 3. 필수 패키지 설치

```bash
sudo dnf update -y

sudo dnf groupinstall -y "Development Tools"

sudo dnf install -y \
  gcc make tar wget curl \
  openssl-devel \
  pcre2-devel \
  zlib-devel \
  systemd-devel \
  libcap-devel
```

기존에 기본 패키지로 HAProxy가 설치되어 있다면 중지한다.

```bash
sudo systemctl disable --now haproxy 2>/dev/null || true
```

---

## 4. HAProxy 사용자 및 디렉터리 생성

```bash
sudo groupadd --system haproxy 2>/dev/null || true

sudo useradd --system \
  --gid haproxy \
  --home-dir /var/lib/haproxy \
  --shell /sbin/nologin \
  haproxy 2>/dev/null || true

sudo mkdir -p /etc/haproxy
sudo mkdir -p /etc/haproxy/certs
sudo mkdir -p /var/lib/haproxy
sudo mkdir -p /run/haproxy

sudo chown -R haproxy:haproxy /var/lib/haproxy
```

---

## 5. HAProxy 3.2.20 다운로드

```bash
cd /usr/local/src

sudo curl -LO https://www.haproxy.org/download/3.2/src/haproxy-3.2.20.tar.gz
sudo curl -LO https://www.haproxy.org/download/3.2/src/haproxy-3.2.20.tar.gz.sha256
```

SHA256 검증을 수행한다.

```bash
cd /usr/local/src
sha256sum -c haproxy-3.2.20.tar.gz.sha256
```

정상이면 다음과 유사하게 출력된다.

```text
haproxy-3.2.20.tar.gz: OK
```

---

## 6. HAProxy 3.2.20 컴파일 및 설치

```bash
cd /usr/local/src
sudo tar xzf haproxy-3.2.20.tar.gz
cd haproxy-3.2.20

sudo make clean

sudo make -j"$(nproc)" \
  TARGET=linux-glibc \
  USE_OPENSSL=1 \
  USE_PCRE2=1 \
  USE_PCRE2_JIT=1 \
  USE_ZLIB=1 \
  USE_SYSTEMD=1 \
  USE_LINUX_CAP=1

sudo make install
```

설치된 버전을 확인한다.

```bash
/usr/local/sbin/haproxy -v
```

예상 출력 형태는 다음과 같다.

```text
HAProxy version 3.2.20 ...
```

빌드 옵션을 확인한다.

```bash
/usr/local/sbin/haproxy -vv | egrep 'HAProxy version|OPTIONS|OPENSSL|PCRE2|ZLIB|SYSTEMD'
```

---

## 7. VIP 바인딩 커널 설정

두 서버 모두에서 설정한다.

```bash
cat <<'EOF_SYSCTL' | sudo tee /etc/sysctl.d/99-haproxy-vip.conf
net.ipv4.ip_nonlocal_bind = 1
EOF_SYSCTL

sudo sysctl --system
```

적용 여부를 확인한다.

```bash
sysctl net.ipv4.ip_nonlocal_bind
```

정상 출력:

```text
net.ipv4.ip_nonlocal_bind = 1
```

---

## 8. 인증서 준비

HAProxy는 일반적으로 인증서와 개인키가 합쳐진 PEM 파일을 사용한다.

예시:

```bash
sudo cat fullchain.pem privkey.pem | sudo tee /etc/haproxy/certs/site.pem >/dev/null
sudo chmod 600 /etc/haproxy/certs/site.pem
sudo chown root:root /etc/haproxy/certs/site.pem
```

최종 인증서 경로는 다음과 같다.

```text
/etc/haproxy/certs/site.pem
```

인증서 파일이 없으면 HAProxy는 시작되지 않는다.

---

## 9. 차단 IP 파일 생성

```bash
sudo touch /etc/haproxy/blocked_ips.lst
sudo chown root:root /etc/haproxy/blocked_ips.lst
sudo chmod 644 /etc/haproxy/blocked_ips.lst
```

차단 IP 추가 예시는 다음과 같다.

```bash
echo "1.2.3.4" | sudo tee -a /etc/haproxy/blocked_ips.lst
```

CIDR 단위 차단도 사용할 수 있다.

```bash
echo "203.0.113.0/24" | sudo tee -a /etc/haproxy/blocked_ips.lst
```

설정 반영은 reload로 처리한다.

```bash
sudo systemctl reload haproxy
```

---

## 10. HAProxy 설정 파일 작성

설정 파일 경로는 다음과 같다.

```text
/etc/haproxy/haproxy.cfg
```

아래 내용을 작성한다.

```haproxy
#---------------------------------------------------------------------
# HAProxy 3.2.20 configuration
# Rocky Linux 9
#
# Purpose:
#   1) X-Forwarded-For spoofing protection
#   2) TLS 1.2+ with strong ciphers only
#
# Network:
#   VIP: 211.43.190.100
#   Backend web1: 10.100.21.100:80
#   Backend web2: 10.100.21.101:80
#---------------------------------------------------------------------

global
    log stdout format raw local0 info

    user haproxy
    group haproxy
    master-worker

    maxconn 50000

    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s

    #-----------------------------------------------------------------
    # TLS security baseline
    # - TLS 1.2 이상만 허용
    # - TLS 1.2 Cipher는 ECDHE + AEAD 계열만 허용
    # - TLS 1.3 CipherSuite는 별도 지정
    #-----------------------------------------------------------------
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

    # TLS 1.2 이하에서 사용하는 Cipher
    ssl-default-bind-ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305

    # TLS 1.3에서 사용하는 CipherSuite
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
    bind 211.43.190.100:80
    mode http

    http-request redirect scheme https code 301

#---------------------------------------------------------------------
# HTTPS frontend
# 외부 사용자는 VIP 211.43.190.100:443 으로 접속
#---------------------------------------------------------------------
frontend fe_https
    bind 211.43.190.100:443 ssl crt /etc/haproxy/certs/site.pem alpn h2,http/1.1
    mode http

    #-------------------------------------------------------------
    # IP 차단은 절대 X-Forwarded-For 기준으로 하지 않음
    # 실제 HAProxy가 관측한 접속 IP인 src 기준으로 차단
    #-------------------------------------------------------------
    acl blocked_src src -f /etc/haproxy/blocked_ips.lst
    http-request deny deny_status 403 if blocked_src

    #-------------------------------------------------------------
    # 공격자가 보낸 기존 X-Forwarded-For를 로그에 남기고 싶을 때
    # 이 capture는 set-header 이전에 수행됨
    #-------------------------------------------------------------
    http-request capture req.hdr(X-Forwarded-For) len 128

    #-------------------------------------------------------------
    # XFF 조작 방지 핵심 설정
    #
    # option forwardfor 사용 금지:
    # - 기존 XFF 뒤에 추가되는 방식이므로 해석 오류 가능
    #
    # set-header 사용:
    # - 기존 헤더를 제거한 뒤 HAProxy가 관측한 실제 src로 덮어씀
    #-------------------------------------------------------------
    http-request del-header Forwarded
    http-request set-header X-Forwarded-For %[src]
    http-request set-header X-Real-IP %[src]
    http-request set-header X-Forwarded-Proto https
    http-request set-header X-Forwarded-Port 443
    http-request set-header X-Forwarded-Host %[req.hdr(Host)]

    #-------------------------------------------------------------
    # 직접 접속 환경에서 사용자가 XFF를 보내면 아예 차단하고 싶다면
    # 아래 한 줄을 set-header보다 위에 추가해서 사용할 수 있음
    #
    # http-request deny deny_status 400 if { req.hdr(X-Forwarded-For) -m found }
    #-------------------------------------------------------------

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
# 외부 공개 금지. SSH 터널 또는 로컬에서만 확인 권장.
#---------------------------------------------------------------------
frontend fe_stats
    bind 127.0.0.1:8404
    mode http

    stats enable
    stats uri /stats
    stats refresh 10s
    stats auth admin:CHANGE_ME_STRONG_PASSWORD
```

권한을 설정한다.

```bash
sudo chown root:root /etc/haproxy/haproxy.cfg
sudo chmod 644 /etc/haproxy/haproxy.cfg
```

---

## 11. systemd 서비스 등록

서비스 파일을 생성한다.

```bash
cat <<'EOF_SERVICE' | sudo tee /etc/systemd/system/haproxy.service
[Unit]
Description=HAProxy Load Balancer
Documentation=man:haproxy(1)
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
RuntimeDirectory=haproxy
EnvironmentFile=-/etc/sysconfig/haproxy

ExecStartPre=/usr/local/sbin/haproxy -Ws -c -f /etc/haproxy/haproxy.cfg
ExecStart=/usr/local/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy/haproxy.pid $OPTIONS

ExecReload=/usr/local/sbin/haproxy -Ws -c -f /etc/haproxy/haproxy.cfg
ExecReload=/bin/kill -USR2 $MAINPID

KillMode=mixed
Restart=always
RestartSec=2

LimitNOFILE=100000

[Install]
WantedBy=multi-user.target
EOF_SERVICE
```

환경 파일을 생성한다.

```bash
cat <<'EOF_ENV' | sudo tee /etc/sysconfig/haproxy
OPTIONS=
EOF_ENV
```

systemd에 반영한다.

```bash
sudo systemctl daemon-reload
```

---

## 12. 설정 검사

서비스 시작 전에 설정 문법을 검사한다.

```bash
sudo /usr/local/sbin/haproxy -c -f /etc/haproxy/haproxy.cfg
```

정상이면 다음과 같이 출력된다.

```text
Configuration file is valid
```

---

## 13. HAProxy 시작 및 활성화

```bash
sudo systemctl enable --now haproxy
sudo systemctl status haproxy
```

정상 상태는 다음과 같다.

```text
active (running)
```

로그 확인:

```bash
sudo journalctl -u haproxy -f
```

---

## 14. 방화벽 설정

`firewalld`를 사용하는 경우 HTTP와 HTTPS 포트를 허용한다.

```bash
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload
```

Stats 페이지는 `127.0.0.1:8404`에만 바인딩했으므로 외부에 개방하지 않는다.

---

## 15. TLS 테스트

TLS 1.0은 실패해야 한다.

```bash
openssl s_client -connect 211.43.190.100:443 -tls1
```

TLS 1.1은 실패해야 한다.

```bash
openssl s_client -connect 211.43.190.100:443 -tls1_1
```

TLS 1.2는 성공해야 한다.

```bash
openssl s_client -connect 211.43.190.100:443 -tls1_2
```

TLS 1.3도 환경에서 지원하면 성공해야 한다.

```bash
openssl s_client -connect 211.43.190.100:443 -tls1_3
```

도메인 인증서에서 SNI가 필요한 경우 다음처럼 `-servername`을 추가한다.

```bash
openssl s_client -connect 211.43.190.100:443 -servername example.com -tls1_2
```

---

## 16. XFF 조작 방지 테스트

외부에서 조작된 XFF를 넣어 요청한다.

```bash
curl -k -H "X-Forwarded-For: 1.2.3.4" https://211.43.190.100/
```

정상 동작 기준은 다음과 같다.

| 항목 | 기대 결과 |
|---|---|
| 공격자가 보낸 XFF | `1.2.3.4` |
| 백엔드가 받는 XFF | HAProxy가 관측한 실제 접속 IP |
| 차단 판단 기준 | `X-Forwarded-For`가 아니라 `src` |

백엔드 웹서버 로그에서 `X-Forwarded-For`가 `1.2.3.4`로 남으면 설정이 잘못된 것이다.

---

## 17. 차단 IP 테스트

차단 파일에 테스트 IP를 추가한다.

```bash
echo "1.2.3.4" | sudo tee -a /etc/haproxy/blocked_ips.lst
sudo systemctl reload haproxy
```

단, 실제 테스트는 클라이언트의 실제 출발지 IP가 차단 목록과 일치해야 한다.

HAProxy는 다음 설정에 의해 XFF가 아니라 실제 접속 IP를 기준으로 차단한다.

```haproxy
acl blocked_src src -f /etc/haproxy/blocked_ips.lst
http-request deny deny_status 403 if blocked_src
```

---

## 18. 백엔드 웹서버 주의사항

백엔드가 Nginx라면 `X-Forwarded-For`를 무조건 신뢰하면 안 된다.

반드시 HAProxy 내부 IP만 신뢰해야 한다.

예시:

```nginx
set_real_ip_from 10.100.20.1;
set_real_ip_from 10.100.20.2;
real_ip_header X-Forwarded-For;
real_ip_recursive off;
```

다음과 같은 설정은 피한다.

```nginx
set_real_ip_from 0.0.0.0/0;
```

이렇게 설정하면 백엔드에서 다시 XFF 조작 위험이 발생한다.

---

## 19. 운영 명령어

설정 검사:

```bash
sudo /usr/local/sbin/haproxy -c -f /etc/haproxy/haproxy.cfg
```

재시작:

```bash
sudo systemctl restart haproxy
```

무중단 reload:

```bash
sudo systemctl reload haproxy
```

상태 확인:

```bash
sudo systemctl status haproxy
```

로그 확인:

```bash
sudo journalctl -u haproxy -f
```

버전 확인:

```bash
/usr/local/sbin/haproxy -v
```

빌드 옵션 확인:

```bash
/usr/local/sbin/haproxy -vv
```

---

## 20. 문제 해결

### 20.1 VIP 바인딩 실패

오류 예시:

```text
cannot bind socket [211.43.190.100:443]
```

확인:

```bash
sysctl net.ipv4.ip_nonlocal_bind
```

값이 `0`이면 다음을 다시 적용한다.

```bash
sudo sysctl -w net.ipv4.ip_nonlocal_bind=1
```

영구 설정:

```bash
cat <<'EOF_SYSCTL' | sudo tee /etc/sysctl.d/99-haproxy-vip.conf
net.ipv4.ip_nonlocal_bind = 1
EOF_SYSCTL

sudo sysctl --system
```

### 20.2 인증서 오류

확인:

```bash
sudo ls -l /etc/haproxy/certs/site.pem
sudo openssl x509 -in /etc/haproxy/certs/site.pem -noout -subject -issuer -dates
```

개인키와 인증서가 하나의 PEM 파일에 포함되어 있어야 한다.

### 20.3 설정 문법 오류

확인:

```bash
sudo /usr/local/sbin/haproxy -c -f /etc/haproxy/haproxy.cfg
```

오류 라인을 확인한 뒤 수정한다.

### 20.4 백엔드 헬스체크 실패

확인:

```bash
curl -v http://10.100.21.100/
curl -v http://10.100.21.101/
```

백엔드 서버에서 `/` 경로가 `2xx` 또는 `3xx`를 반환해야 한다.

다른 헬스체크 경로를 사용할 경우 아래 설정을 변경한다.

```haproxy
option httpchk GET /
```

예시:

```haproxy
option httpchk GET /health
```

---

## 21. 최종 점검표

| 점검 항목 | 명령 또는 기준 | 결과 |
|---|---|---|
| HAProxy 버전 | `/usr/local/sbin/haproxy -v` | `3.2.20` |
| 설정 문법 | `haproxy -c -f /etc/haproxy/haproxy.cfg` | valid |
| VIP 바인딩 옵션 | `sysctl net.ipv4.ip_nonlocal_bind` | `1` |
| HTTP 접속 | `curl -I http://211.43.190.100` | HTTPS redirect |
| HTTPS 접속 | `curl -k -I https://211.43.190.100` | 200/30x |
| TLS 1.0 | `openssl s_client -tls1` | 실패 |
| TLS 1.1 | `openssl s_client -tls1_1` | 실패 |
| TLS 1.2 | `openssl s_client -tls1_2` | 성공 |
| XFF 조작 | `curl -H "X-Forwarded-For: 1.2.3.4"` | 백엔드에서 실제 src로 덮어씀 |
| IP 차단 | `blocked_ips.lst` + reload | 실제 src 기준 차단 |

---

## 22. 참고 URL

- HAProxy 3.2 다운로드  
  https://www.haproxy.org/download/3.2/src/

- HAProxy 3.2 문서  
  https://docs.haproxy.org/3.2/configuration.html

- HAProxy 소스 설치 문서  
  https://github.com/haproxy/haproxy/blob/master/INSTALL

---

## 23. 권장 운영 결론

```text
HAProxy 버전: 3.2.20
운영체제: Rocky Linux 9
Listen IP: 211.43.190.100:80, 443
XFF 처리: set-header로 무조건 덮어쓰기
차단 기준: XFF가 아니라 src 기준
TLS: TLS 1.2 이상만 허용
TLS 1.2 Cipher: ECDHE + AES-GCM / CHACHA20-POLY1305만 허용
Keepalived 연동: ip_nonlocal_bind=1 필수
```

---

### 💾 Download

- [https://www.haproxy.org/download/](https://www.haproxy.org/download/)
