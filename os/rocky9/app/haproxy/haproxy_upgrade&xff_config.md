# HAProxy 버전 업그레이드(v3.2.20) 및 XFF 설정
기존 dnf로 설치된 Haproxy에서 대상 버전으로 업그레이드
최신 TLS와 앞단 X-Forwarded-For 설정

---

## 1. HAProxy 버전 업그레이드(v3.2.20)
### 1.1 HAProxy v3.2.20 다운로드

```bash
cd /usr/local/src

sudo curl -LO https://www.haproxy.org/download/3.2/src/haproxy-3.2.20.tar.gz
sudo curl -LO https://www.haproxy.org/download/3.2/src/haproxy-3.2.20.tar.gz.sha256
```

SHA256 검증을 수행.

```bash
cd /usr/local/src
sha256sum -c haproxy-3.2.20.tar.gz.sha256
```

정상이면 다음과 같이 출력.

```text
haproxy-3.2.20.tar.gz: OK
```

### 1.2 HAProxy 3.2.20 컴파일 및 설치

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

설치된 버전.(source 파일 설치 시 /usr/local/sbin 하위 실행 파일 생성)

```bash
/usr/local/sbin/haproxy -v
```

### 1.3 systemd 서비스 파일 변경
기존 설치되어 있는 haproxy 대신 업그레이드된 haproxy 로 실행 파일 변경
```
vi /usr/lib/systemd/system/haproxy.service

[Unit]
Description=HAProxy Load Balancer
After=network-online.target
Wants=network-online.target

[Service]
EnvironmentFile=-/etc/sysconfig/haproxy
Environment="CONFIG=/etc/haproxy/haproxy.cfg" "PIDFILE=/run/haproxy.pid" "CFGDIR=/etc/haproxy/conf.d"
#ExecStartPre=/usr/sbin/haproxy -f $CONFIG -f $CFGDIR -c -q $OPTIONS
#ExecStart=/usr/sbin/haproxy -Ws -f $CONFIG -f $CFGDIR -p $PIDFILE $OPTIONS
#ExecReload=/usr/sbin/haproxy -f $CONFIG -f $CFGDIR -c -q $OPTIONS
ExecStartPre=/usr/local/sbin/haproxy -f $CONFIG -f $CFGDIR -c -q $OPTIONS
ExecStart=/usr/local/sbin/haproxy -Ws -f $CONFIG -f $CFGDIR -p $PIDFILE $OPTIONS
ExecReload=/usr/local/sbin/haproxy -f $CONFIG -f $CFGDIR -c -q $OPTIONS

ExecReload=/bin/kill -USR2 $MAINPID
KillMode=mixed
SuccessExitStatus=143
Type=notify

[Install]
WantedBy=multi-user.target

데몬 리로드
systemctl daemon-reload
```

## 2. TLS 및 XFF 설정 예시(중요 - global, frontend Section)
```
vi /etc/haproxy/haproxy.cfg

global
    ... 생략 ...

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
    ... 생략 ...

#---------------------------------------------------------------------
# HTTP frontend
# (모든 80 포트 트래픽은 HTTPS로 리다이렉트 처리한다고 가정)
#---------------------------------------------------------------------
frontend fe_http
    bind xxx.xxx.xxx.xxx:80
    mode http

    http-request redirect scheme https code 301

#---------------------------------------------------------------------
# HTTPS frontend
# X-Forwarded-For 설정
#---------------------------------------------------------------------
frontend fe_https
    bind xxx.xxx.xxx.xxx:443 ssl crt /etc/haproxy/certs/site.pem alpn h2,http/1.1
    mode http

    #-------------------------------------------------------------
    # (Option)IP 차단은 절대 X-Forwarded-For 기준으로 하지 않음
    # 실제 HAProxy가 관측한 접속 IP인 src 기준으로 차단
    #-------------------------------------------------------------
    acl blocked_src src -f /etc/haproxy/blocked_ips.lst
    http-request deny deny_status 403 if blocked_src

    #-------------------------------------------------------------
    # 전체 X-Forwarded-For를 로그에 남기고 싶을 때
    # 이 capture는 set-header 이전에 수행됨
    #-------------------------------------------------------------
    http-request capture req.fhdr(X-Forwarded-For) len 512

    #-------------------------------------------------------------
    # XFF 조작 방지 핵심 설정
    #
    # option forwardfor 사용 금지:
    # - 기존 XFF 뒤에 추가되는 방식이므로 해석 오류 가능
    #
    # set-header 사용:
    # - Haproxy 관측 실제 src와 전체 헤더의 XFF 내용을 뒤에 덧붙임.
    #-------------------------------------------------------------
    http-request del-header Forwarded
    http-request set-header X-Forwarded-For %[src],%[req.fhdr(X-Forwarded-For)] if { req.fhdr(X-Forwarded-For) -m found }
    http-request set-header X-Real-IP %[src]
    http-request set-header X-Forwarded-Proto https
    http-request set-header X-Forwarded-Port 443
    http-request set-header X-Forwarded-Host %[req.hdr(Host)]

    default_backend be_web

#---------------------------------------------------------------------
# Backend web servers
# 내부 웹서버와는 내부망으로 통신
#---------------------------------------------------------------------
backend be_web
    mode http
    balance roundrobin

    option httpchk GET /
    http-check expect rstatus ^(2|3)[0-9][0-9]$

    default-server inter 3s fall 3 rise 2

    server web1 10.10.10.100:80 check
    server web2 10.10.10.101:80 check

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
