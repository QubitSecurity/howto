Ivanti SSL VPN(구 Pulse Secure) 앞단에 NGINX를 웹 프록시로 구성하는 경우, **UDP 4500(IPsec NAT-T)** 같은 **비HTTP 트래픽은 프록시를 통과할 수 없습니다**. 아래 내용을 참고해 실제 구성 가능한 방안을 안내드리겠습니다.

---

## ✅ 전제 확인: Ivanti VPN 구성과 UDP 4500 포트

Ivanti SSL VPN은 다음 두 가지 유형의 터널링 방식을 사용할 수 있습니다:

| 방식          | 포트           | 설명                     |
| ----------- | ------------ | ---------------------- |
| ESP (IPsec) | 프로토콜 50      | NAT 환경에서 문제 발생 가능      |
| NAT-T (UDP) | **UDP 4500** | NAT 우회용 IPsec over UDP |

> **UDP 4500은 TLS 웹 프록시(NGINX, Apache 등)로 중계할 수 없습니다.**

---

## ❌ NGINX로는 SSL VPN 트래픽 중계 불가능

NGINX는 L7 웹 프록시이므로 \*\*HTTPS 트래픽(TCP 443)\*\*까지만 처리할 수 있고, **UDP 4500은 프록시 불가**입니다. 즉, 다음 구조는 동작하지 않습니다:

```plaintext
Client ──TLS──> NGINX ──TLS──> Ivanti SSL VPN (UDP 4500 필수)
```

UDP는 프록시를 통해 터널링할 수 없으므로, VPN 연결이 실패합니다.

---

## ✅ 가능한 구성 방법

### 1. **L4 Load Balancer 활용 (예: HAProxy, NGINX Stream, LVS)**

* NGINX의 **stream 모듈**을 사용하면 TCP/UDP 패스스루 가능
* 단, 인증서는 Ivanti가 처리

```nginx
# /etc/nginx/nginx.conf (stream 블록)
stream {
    server {
        listen 4500 udp;
        proxy_pass 10.0.0.10:4500;  # Ivanti VPN 서버 IP
    }

    server {
        listen 443 ssl;
        proxy_pass 10.0.0.10:443;
        ssl_certificate     /etc/nginx/certs/fullchain.pem;
        ssl_certificate_key /etc/nginx/certs/privkey.pem;
    }
}
```

> 참고: `stream`은 일반 NGINX build에는 포함되어 있지 않으며, `--with-stream` 옵션으로 빌드하거나 `nginx-full` 설치 필요

### 2. **SSL Termination + TCP Pass-through 분리 구성**

* 인증은 NGINX에서 수행
* UDP 및 기타 터널링 포트는 직접 Ivanti로 전달

```plaintext
[HTTPS Portal 접속용]
Client ──HTTPS──> NGINX ──HTTPS──> Ivanti SSL VPN (TCP 443)

[VPN 통신용]
Client ──────────UDP 4500──────────> Ivanti SSL VPN (Bypass NGINX)
```

즉, **NGINX는 인증 포털만 처리**하고, 실제 VPN 터널링은 프록시 우회해야 합니다.

---

## ✅ 방화벽/포트 구성 체크리스트

| 항목               | 설명                 |
| ---------------- | ------------------ |
| 🔓 TCP 443       | Ivanti 포털 접근용      |
| 🔓 UDP 4500      | NAT-T용 VPN 터널링     |
| 🔒 TCP 80        | 리디렉션 또는 비활성화 가능    |
| 🔒 ESP (프로토콜 50) | 필요 시 허용 (IPsec 기본) |

---

## ✅ 기타 권장 사항

* VPN 접속용 FQDN이 `vpn.example.com`이라면, **UDP 트래픽은 NGINX가 없는 경로로 분기**되어야 합니다.
* DNS와 방화벽 라우팅을 이용한 **포트별 분기 또는 IP별 분기** 고려 필요
* Ivanti는 L7 리버스 프록시 환경보다는 L4 패스스루 환경을 전제로 설계되어 있음

---

## ✅ 결론

| 항목                  | 가능 여부 | 설명                   |
| ------------------- | ----- | -------------------- |
| NGINX에서 UDP 4500 중계 | ❌ 불가  | UDP는 웹 프록시에서 중계 불가   |
| NGINX stream 모듈 사용  | ⭕ 가능  | TCP/UDP 패스스루 구성 가능   |
| 인증용 HTTPS 프록시       | ⭕ 가능  | 인증 웹 UI는 NGINX 처리 가능 |
| 터널링 분리 구성           | ⭕ 가능  | VPN 트래픽은 프록시 우회 필요   |

---


