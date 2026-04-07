## 🔐 Rocky Linux 10 + HAProxy + OpenSSL (3.5 / 3.6 / 4.0) 기반 PQC 테스트 HOWTO
핵심은 “**OpenSSL 3.5+ (또는 3.6 / 4.0 preview) 기반 → HAProxy를 직접 링크 빌드 → PQC 하이브리드 TLS 1.3 검증**” 입니다.

## 📌 목적

* **PQC(Post-Quantum Cryptography)** 환경에서
* HAProxy를 TLS 종료 지점으로 구성하고
* **하이브리드 키 교환 (ML-KEM 기반)** 테스트 수행

---

## ⚠️ 전제 조건 (중요)

* 현재 PQC 적용의 현실:

  * ✅ **키 교환 (KEM) 하이브리드 → 가능 (테스트 권장)**
  * ⚠️ **서명 (ML-DSA 인증서) → 아직 운영 비권장**
* 즉,

  > **기존 인증서 유지 + PQC Hybrid Key Exchange 테스트가 핵심**

---

# 1️⃣ 시스템 준비 (Rocky Linux 10)

```bash
dnf update -y
dnf groupinstall "Development Tools" -y
dnf install -y wget git perl-core zlib-devel pcre2-devel systemd-devel libtool
```

---

# 2️⃣ OpenSSL 최신 버전 빌드

👉 공식 소스: [https://openssl-library.org/source/](https://openssl-library.org/source/)

## 📌 버전 전략

| 버전  | 용도          |
| --- | ----------- |
| 3.5 | 안정 + PQC 포함 |
| 3.6 | 최신 안정       |
| 4.0 | 차세대 (실험적)   |

---

## 2.1 OpenSSL 3.6 설치 (권장 기준)

```bash
cd /usr/local/src
wget https://www.openssl.org/source/openssl-3.6.0.tar.gz
tar xzf openssl-3.6.0.tar.gz
cd openssl-3.6.0

./Configure --prefix=/usr/local/openssl-3.6 \
            --openssldir=/usr/local/openssl-3.6 \
            enable-tls1_3

make -j$(nproc)
make install
```

---

## 2.2 OpenSSL 4.0 (실험)

```bash
wget https://www.openssl.org/source/openssl-4.0.0-alpha.tar.gz
tar xzf openssl-4.0.0-alpha.tar.gz
cd openssl-4.0.0-alpha

./Configure --prefix=/usr/local/openssl-4.0 \
            enable-tls1_3

make -j$(nproc)
make install
```

---

## 2.3 환경 변수 설정

```bash
export PATH=/usr/local/openssl-3.6/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/openssl-3.6/lib64:$LD_LIBRARY_PATH

openssl version
```

👉 반드시 확인:

```
OpenSSL 3.6.x
```

---

# 3️⃣ PQC 알고리즘 확인

```bash
openssl list -kem-algorithms
openssl list -signature-algorithms
```

👉 기대 결과 (예시):

```
ML-KEM-768
ML-KEM-1024
ML-DSA
SLH-DSA
```

---

# 4️⃣ HAProxy 최신 버전 빌드

## 📌 핵심 포인트

> HAProxy 버전보다 **링크된 OpenSSL 버전이 더 중요**

---

## 4.1 소스 다운로드

```bash
cd /usr/local/src
wget http://www.haproxy.org/download/3.3/src/haproxy-3.3.5.tar.gz
tar xzf haproxy-3.3.5.tar.gz
cd haproxy-3.3.5
```

---

## 4.2 OpenSSL 3.6 링크 빌드

```bash
make -j$(nproc) \
  TARGET=linux-glibc \
  USE_OPENSSL=1 \
  SSL_INC=/usr/local/openssl-3.6/include \
  SSL_LIB=/usr/local/openssl-3.6/lib64 \
  USE_PCRE2=1 \
  USE_ZLIB=1

make install
```

---

## 4.3 빌드 확인

```bash
haproxy -vv
```

👉 반드시 확인:

```
Built with OpenSSL version : OpenSSL 3.6.x
```

---

# 5️⃣ TLS 1.3 + PQC Hybrid 설정

## 📌 기본 개념

* TLS 1.3에서
* **기존 ECDHE + ML-KEM Hybrid Key Exchange**

---

## 5.1 테스트용 인증서 생성

```bash
openssl req -x509 -newkey rsa:2048 \
  -keyout server.key \
  -out server.crt \
  -days 365 -nodes
```

---

## 5.2 HAProxy 설정

```cfg
global
    ssl-default-bind-options ssl-min-ver TLSv1.3

defaults
    mode http
    timeout connect 5s
    timeout client  30s
    timeout server  30s

frontend https-in
    bind *:443 ssl crt /etc/haproxy/server.pem \
        ssl-default-bind-ciphersuites TLS_AES_256_GCM_SHA384

    default_backend web

backend web
    server s1 127.0.0.1:8080
```

---

## ⚠️ PQC 핵심 설정 포인트

현재 HAProxy에서 직접 PQC 설정은 제한적 →
👉 **OpenSSL 레벨에서 활성화됨**

---

# 6️⃣ PQC Hybrid 테스트 (핵심 단계)

## 6.1 OpenSSL 클라이언트 테스트

```bash
openssl s_client -connect localhost:443 -tls1_3 -groups X25519:MLKEM768
```

👉 확인 포인트:

```
Key Exchange: Hybrid (X25519 + ML-KEM)
```

---

## 6.2 Chrome 테스트

* Chrome 131+ 기준
* 내부적으로 ML-KEM hybrid 사용

확인 방법:

```
chrome://net-export
```

또는 DevTools → Security

---

# 7️⃣ 성능 및 영향 테스트

## 📌 반드시 확인

| 항목                | 이유          |
| ----------------- | ----------- |
| Handshake Size    | PQC는 크기가 큼  |
| Latency           | 초기 연결 증가    |
| MTU Fragmentation | 패킷 분할 발생 가능 |
| LB/Firewall 영향    | 장비 호환성      |

---

# 8️⃣ 운영 적용 전략

## ✅ 추천 순서

1. OpenSSL 3.5+ 적용
2. HAProxy 재빌드
3. Hybrid Key Exchange 테스트
4. 성능 검증
5. 일부 트래픽 Canary 적용
6. 점진 확대

---

## ❌ 아직 비권장

* ML-DSA 인증서 전면 적용
* 기존 TLS 완전 대체

---

# 9️⃣ 문제 해결 체크리스트

## 9.1 PQC 미적용

```bash
haproxy -vv
```

→ OpenSSL 버전 확인

---

## 9.2 Hybrid 협상 실패

```bash
openssl s_client -groups
```

→ 지원 그룹 확인

---

## 9.3 성능 문제

* MTU 조정
* TLS record size 조정
* Keepalive 증가

---

# 🔟 핵심 요약

> **지금 단계의 PQC는 “도입 완료”가 아니라 “하이브리드 검증 단계”입니다.**

* HAProxy 자체보다 **OpenSSL이 핵심**
* **ML-KEM 기반 Hybrid Key Exchange부터 시작**
* 인증서는 기존 유지

---

# 🚀 결론

> **Rocky Linux + HAProxy 환경에서는 이미 PQC 테스트가 가능한 단계이며,  
> 실무적으로는 OpenSSL 3.5+/3.6 기반 Hybrid TLS 검증이 가장 현실적인 접근입니다.**

---

다음 단계로:

👉 **HAProxy 실제 운영 설정 (production-grade 튜닝 + 체크리스트)**
👉 **PLURA-XDR 관점에서 PQC 트래픽 분석/탐지 전략**
