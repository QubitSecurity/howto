# 🛡️ Ivanti SSL VPN 앞단 프록시 구성 가이드

이 리포지토리는 **Ivanti SSL VPN 시스템을 외부에 노출하지 않고**, 웹 프록시 및 L4 프록시를 통해 **안전하게 접근**할 수 있도록 구성하는 문서를 포함합니다.

Ivanti는 HTTPS 기반의 포털(Web UI)과 UDP 기반의 VPN 터널링(UDP 4500)을 모두 사용하므로, 단순한 리버스 프록시만으로는 구성할 수 없습니다. 이에 따라 포털과 터널링을 분리하여 처리하는 구조로 설계되었습니다.

---

## 📄 문서 구성

| 파일명             | 설명 |
|------------------|------|
| `howto.md`       | Ivanti VPN 앞단에 **NGINX Stream 모듈을 활용한 기본 프록시 구성 방법**을 안내합니다. |
| `with-haproxy.md`| **HAProxy + NGINX 조합**을 통해 TCP 443 (포털)과 UDP 4500 (VPN 터널링)을 각각 처리하는 고급 구성을 제공합니다. |

---

## 🔧 구성 개요

### 1. TCP 443 (포털 접속)

- 인증서 처리를 위한 **NGINX Web Proxy** 구성
- 외부 사용자는 `vpn.example.com`을 통해 포털 접속
- 프록시 순서: `HAProxy → NGINX → Ivanti`

### 2. UDP 4500 (VPN 터널링)

- NAT-T용 VPN 터널링은 **HAProxy에서 직접 Ivanti로 포워딩**
- `L4 패스스루` 방식으로 처리
- 프록시 순서: `HAProxy → Ivanti`

---

## ⚙️ 적용 대상

- Ivanti Connect Secure / Ivanti Neurons Secure Access
- SSL VPN을 외부 노출 없이 구성하려는 기관
- DMZ/내부망 환경에서 **Ivanti 직접 노출을 피하고 싶은 경우**
- 포털(HTTPS)과 터널링(UDP)의 분리 구성이 필요한 보안 환경

---

## 📦 사용 예시

```bash
# 포털 테스트
curl -vk https://vpn.example.com

# VPN 연결 (UDP 4500 통신 확인은 실제 클라이언트로 테스트)
````

---

## 🧩 추가 정보

* NGINX를 통한 TLS Termination 구성도 가능합니다 (`howto.md`)
* L4 계층 분리 및 고가용성 구성이 필요한 경우 `with-haproxy.md`를 참고하세요
* UDP 4500은 L7 프록시 불가 → 반드시 L4 프록시로 구성해야 합니다

---
