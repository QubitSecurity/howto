아래는 **HAProxy 기반 L4 프록시 구성 예제**입니다:

---

## ✅ 아키텍처 요약

| 구성 요소    | 동작 역할     | 처리 주체                                   |
| -------- | --------- | --------------------------------------- |
| TCP 443  | 포털 접속 프록시 | **HAProxy → NGINX(Web Proxy) → Ivanti** |
| UDP 4500 | VPN 터널 중계 | **HAProxy → Ivanti** (L4 passthrough)   |

---

## 📁 HAProxy 설정 파일 예시 (`/etc/haproxy/haproxy.cfg`)

```haproxy
global
    log /dev/log local0
    maxconn 2048
    daemon

defaults
    log     global
    mode    tcp
    option  tcplog
    timeout connect 10s
    timeout client  1m
    timeout server  1m

# ✅ TCP 443: 웹 포털 프록시 → NGINX로 포워딩
frontend https_portal
    bind *:443
    mode tcp
    default_backend nginx_web_proxy

backend nginx_web_proxy
    mode tcp
    server nginx1 192.168.1.10:443 check  # NGINX 서버 (Web Proxy)

# ✅ UDP 4500: VPN NAT-T 터널링 → Ivanti 장비로 직접 포워딩
frontend vpn_udp
    bind *:4500 proto udp
    mode tcp
    default_backend ivanti_udp

backend ivanti_udp
    mode tcp
    server ivanti1 192.168.1.20:4500 check  # Ivanti VPN 장비 IP
```

---

## 📁 NGINX 설정 (Web Proxy)

Ivanti의 포털은 HTTPS를 사용하므로 NGINX는 reverse proxy 역할을 수행합니다:

```nginx
server {
    listen 443 ssl;
    server_name vpn.example.com;

    ssl_certificate     /etc/nginx/certs/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/privkey.pem;

    location / {
        proxy_pass https://192.168.1.20;  # Ivanti 포털 주소
        proxy_ssl_verify       off;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

> NGINX는 TLS termination 수행 (SSL 인증서는 여기서 적용)

---

## 🔐 방화벽 및 네트워크 조건

| 포트/프로토콜     | 설명                          |
| ----------- | --------------------------- |
| TCP 443     | HAProxy → NGINX → Ivanti 포털 |
| UDP 4500    | HAProxy → Ivanti VPN 터널     |
| TCP 80 (선택) | HTTP → HTTPS 리디렉션용          |

---

## 🧪 테스트 시나리오

1. `https://vpn.example.com` 접속 → HAProxy → NGINX → Ivanti 포털 UI 표시
2. VPN 클라이언트 연결 시 UDP 4500 → HAProxy → Ivanti로 터널링

---

## 📌 운영 팁

* HAProxy는 L4 수준에서 단순 포트 중계만 하므로 부하 분산은 제한적
* NGINX는 HTTPS termination 및 URI 조작이 가능하므로 포털 보안 강화에 적합
* Ivanti는 UDP 트래픽을 직접 받아야 하므로 HAProxy가 있는 서버에서 **UDP 4500 포워딩이 정확히 되어야 함**
* `mode tcp`은 UDP에 적합하지 않지만 HAProxy는 UDP 트래픽도 지원하며 v2.0 이상에서 `bind *:4500 proto udp` 사용 가능

---
