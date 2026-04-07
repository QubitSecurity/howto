Rocky Linux 9에서 `haproxy-3.0.5`를 소스 파일을 이용해 설치하고, 사용자 계정 생성 및 설정까지 포함한 설치 방법을 안내드리겠습니다. 이 과정에서는 필요한 라이브러리 설치, 소스 다운로드, 컴파일, 사용자 계정 생성, 설정 파일 구성, 그리고 서비스를 설정하는 과정을 포함합니다.

### 1. 필수 패키지 설치
먼저, HAProxy 컴파일에 필요한 필수 패키지와 라이브러리를 설치합니다.

```bash
sudo dnf install -y gcc make pcre-devel openssl-devel systemd-devel tar wget
```

### 2. HAProxy 소스 다운로드
HAProxy 3.0.5 소스를 다운로드하고 압축을 해제합니다.

```bash
wget https://www.haproxy.org/download/3.0/src/haproxy-3.0.5.tar.gz
tar -zxvf haproxy-3.0.5.tar.gz
cd haproxy-3.0.5
```

### 3. HAProxy 컴파일 및 설치
컴파일 시 OpenSSL 지원을 포함하기 위해 `USE_OPENSSL` 옵션을 사용하고, Linux 환경에 맞춰 컴파일합니다.

```bash
make TARGET=linux-glibc USE_OPENSSL=1 USE_PCRE=1 USE_SYSTEMD=1
sudo make install
```

이 명령어는 HAProxy를 `/usr/local/sbin/haproxy`에 설치합니다.

### 4. `haproxy` 사용자 및 그룹 생성
HAProxy가 특정 사용자 권한으로 실행될 수 있도록 `haproxy` 사용자와 그룹을 생성합니다.

```bash
sudo groupadd haproxy
sudo useradd -r -g haproxy haproxy
```

여기서 `-r` 옵션은 시스템 계정으로 사용자를 생성합니다.

### 5. 디렉토리 생성 및 권한 설정
HAProxy가 사용할 디렉토리를 생성하고 적절한 권한을 설정합니다.

```bash
sudo mkdir -p /var/lib/haproxy
sudo mkdir -p /var/run/haproxy
sudo chown -R haproxy:haproxy /var/lib/haproxy
sudo chown -R haproxy:haproxy /var/run/haproxy
```

### 6. 설정 파일 작성
`/etc/haproxy` 디렉토리를 생성하고, 기본 설정 파일을 작성합니다.

```bash
sudo mkdir -p /etc/haproxy
sudo tee /etc/haproxy/haproxy.cfg <<EOF
global
    log 127.0.0.1 local0
    log 127.0.0.1 local0 notice
    maxconn 8192
    user haproxy
    group haproxy
    chroot /var/lib/haproxy
    pidfile /var/run/haproxy.pid
    stats socket /var/run/haproxy.sock mode 777 level admin expose-fd listeners
    nbthread 4
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA256:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA
    ssl-default-bind-options ssl-min-ver TLSv1.0

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 10s
    timeout client 30s
    timeout server 30s
    retries 3

frontend http_frontend_80
    bind *:80
    mode http
    option httpclose
    option forwardfor
    use_backend http_backend_80

backend http_backend_80
    mode http
    balance roundrobin
    option forwardfor
    http-request set-header X-Forwarded-Port %[dst_port]
    server web1 192.168.10.18:80 check
    server web2 192.168.10.19:80 check
EOF
```

### 7. Systemd 서비스 파일 생성
HAProxy를 시스템 서비스로 설정하여 부팅 시 자동으로 시작되도록 서비스 파일을 생성합니다.

```bash
sudo tee /etc/systemd/system/haproxy.service <<EOF
[Unit]
Description=HAProxy Load Balancer
After=network.target

[Service]
ExecStart=/usr/local/sbin/haproxy -f /etc/haproxy/haproxy.cfg -Ws
ExecReload=/bin/kill -USR2 \$MAINPID
Restart=always
User=haproxy
Group=haproxy

[Install]
WantedBy=multi-user.target
EOF
```

### 8. 서비스 시작 및 부팅 시 자동 시작 설정
HAProxy 서비스를 시작하고, 부팅 시 자동으로 시작되도록 설정합니다.

```bash
sudo systemctl daemon-reload
sudo systemctl enable haproxy
sudo systemctl start haproxy
```

### 9. 설치 확인 및 설정 검증
HAProxy가 정상적으로 실행되고 있는지 확인합니다.

```bash
sudo systemctl status haproxy
```

설정 파일을 검증하려면 다음 명령어를 사용합니다:

```bash
/usr/local/sbin/haproxy -f /etc/haproxy/haproxy.cfg -c
```

이 명령어는 설정 파일이 유효한지 검증하며, 오류가 없다면 조용히 종료합니다.

### 요약
위의 단계에 따라 HAProxy 3.0.5를 Rocky Linux 9에서 소스로 설치하고, 사용자 계정 및 서비스 설정을 완료했습니다. 설정 파일을 `/etc/haproxy/haproxy.cfg`에서 수정하여 환경에 맞게 조정할 수 있습니다.
