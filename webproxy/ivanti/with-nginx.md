# 🌐 NGINX 기반 L4 프록시 구성 예제

---

## ✅ 아키텍처 요약

| 구성 요소    | 동작 역할     | 처리 주체                     |
| -------- | --------- | ------------------------- |
| TCP 443  | 포털 접속 프록시 | **NGINX(Web Proxy) → Ivanti** |
| UDP 4500 | VPN 터널 중계 | **NGINX(Stream) → Ivanti**    |

---

## 📊 데이터 흐름 구성도

```mermaid
flowchart LR
    A[🌐 External User]
    B1[🧭 NGINX - TCP 443]
    B2[🧭 NGINX - UDP 4500]
    D[🔐 Ivanti SSL VPN]

    A -->|TCP 443| B1
    B1 -->|TCP 443| D

    A -->|UDP 4500| B2
    B2 -->|UDP 4500| D
````

---

### 🧾 구성 흐름 요약

1. **포털 접속**

   * 사용자는 HTTPS로 `vpn.example.com` 접속
   * `NGINX`는 TCP 443 요청을 받아 SSL Termination 처리 후 Ivanti 포털로 전달

2. **VPN 터널 연결**

   * 클라이언트는 NAT-T(IPsec)용 UDP 4500으로 접속
   * `NGINX stream 모듈`이 UDP 트래픽을 Ivanti로 전달

---

## 📁 실제 적용 코드

### 📌 `/etc/nginx/nginx.conf` 내 UDP 설정

```nginx
# nginx(waf) 의 /etc/nginx/nginx.conf 내 udp 전송 설정 테스트
# nginx.conf 하단에 udp 4500 백엔드 프록시 설정

stream {
    server {
        listen 4500 udp;
        proxy_pass 210.100.218.15:4500;
        proxy_timeout 2m;
    }
}
```

### 📌 설정 반영

```bash
# NGINX 설정 리로드
systemctl reload nginx
```

### 📌 방화벽 규칙 적용

```bash
sudo firewall-cmd --permanent --add-port=4500/udp
sudo firewall-cmd --reload
```

---

## 📁 NGINX HTTPS 설정 (Web Proxy)

```nginx
server {
    listen 443 ssl;
    server_name vpn.example.com;

    ssl_certificate     /etc/nginx/certs/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/privkey.pem;

    location / {
        proxy_pass https://210.100.218.15;  # Ivanti 포털 주소
        proxy_ssl_verify       off;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

---

## 🔐 방화벽 및 네트워크 조건

| 포트/프로토콜     | 설명                    |
| ----------- | --------------------- |
| TCP 443     | NGINX → Ivanti 포털     |
| UDP 4500    | NGINX → Ivanti VPN 터널 |
| TCP 80 (선택) | HTTP → HTTPS 리디렉션용    |

---

## 🧪 테스트 시나리오

1. `https://vpn.example.com` 접속 → NGINX → Ivanti 포털 UI 표시
2. VPN 클라이언트 연결 시 UDP 4500 → NGINX → Ivanti로 터널링

---

## 📌 운영 팁

* **HAProxy는 UDP를 지원하지 않음 → NGINX stream 모듈 사용이 필수**
* UDP 4500은 반드시 **stream 블록**에서 프록시해야 하며, L7 프록시로는 불가
* 고가용성이 필요하다면 `keepalived + NGINX` 조합으로 이중화 가능

---
