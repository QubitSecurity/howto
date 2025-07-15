## ✅ 무결성 검사 방안 (패키지 및 설정 관리 기준: **Gradle / pnpm / Database**)

### 1. **무결성 검사 목적**

* 제품의 핵심 실행 파일, 설정 정보, 데이터베이스 구성 등은 보안 및 운영 안정성과 직결되므로,
* **SHA-256 해시값 기반 기준값 보관 및 비교**, **패키지 의존성 고정 파일 확인**, **설정값 정합성 확인** 등을 통해 변경 여부를 식별합니다.

---

## 1️⃣ Backend (Gradle 기반 Java)

### 📌 대상

* `build.gradle`, `settings.gradle`, `gradle.properties`
* `build/libs/*.jar`, `config/*.yml` 등
* `.gradle` 캐시 디렉토리는 검사 대상에서 제외

### 📌 무결성 관리 방법

* 주요 파일에 대해 **SHA-256 해시값 생성 및 기준값 보관**
* Git으로 버전 관리되므로 commit hash 기반 정합성 검증도 가능
* 빌드된 `.jar` 파일은 배포 전/후 해시 비교 가능

### ✅ 예시 스크립트 (bash)

```bash
sha256sum build.gradle settings.gradle build/libs/app.jar > integrity-backend.txt
```

---

## 2️⃣ Frontend (pnpm 기반 React)

### 📌 대상 파일

* `package.json`
* `pnpm-lock.yaml`
* `dist/` 또는 `build/` 디렉토리의 정적 산출물
* `node_modules/`는 검사 대상 제외 (동적 재생성 가능)

### 📌 무결성 관리 방법

* `pnpm-lock.yaml`은 의존성 무결성 핵심 파일이며, 내부적으로 패키지 해시 정보 포함
* `pnpm install --frozen-lockfile` 사용 시 lockfile과 완전 일치하는 구성으로 설치됨
* 빌드 산출물(`dist/*`)에 대해 SHA-256 기준값을 생성하고 비교

### ✅ 기준값 저장 예시

```bash
sha256sum package.json pnpm-lock.yaml dist/* > integrity-frontend.txt
```

### ✅ 자동 검사 스크립트 예

```bash
#!/bin/bash
echo "[Frontend Integrity Check]"
sha256sum -c integrity-frontend.txt
```

---

## 3️⃣ Database (주요 설정값 무결성 검사)

### 📌 대상 설정값 (MySQL 예시)

| 항목                         | 설명                  |
| -------------------------- | ------------------- |
| `log_bin`                  | 이진 로그 활성화 여부        |
| `require_secure_transport` | 보안 전송 요구 설정         |
| `max_connections`          | 최대 연결 수 제한          |
| 계정 및 권한 설정                 | 사용자/역할/GRANT 구문     |
| 감사 로그 및 백업 정책              | 감사/백업 활성화 및 저장 경로 등 |

### 📌 기준값 저장 방식

* 초기 기준값을 JSON 또는 CSV 형태로 저장
* 정기적으로 현재 설정값을 추출하여 기준값과 비교

### ✅ 무결성 검사 스크립트 예 (bash + MySQL)

```bash
mysql -u root -p'your_pw' -Nse "SELECT @@log_bin, @@require_secure_transport, @@max_connections;" \
| awk '{ print "log_bin="$1"\nrequire_secure_transport="$2"\nmax_connections="$3 }' > db_current_config.txt

sha256sum db_current_config.txt > db_current_config.hash
diff db_current_config.hash db_baseline_config.hash && echo "✔ DB config OK" || echo "❗ DB config Mismatch"
```

---

## 🔄 전체 무결성 검사 요약

| 구분           | 대상 파일/항목                                   | 무결성 기준 관리 방식                  |
| ------------ | ------------------------------------------ | ----------------------------- |
| **Backend**  | `build.gradle`, `*.jar`, 설정 파일 등           | SHA-256 해시값 기준 비교             |
| **Frontend** | `package.json`, `pnpm-lock.yaml`, `dist/*` | 해시값 + lockfile 기반 정합성 확인      |
| **Database** | 주요 설정값 (`log_bin`, 인증, 연결 수 등)             | 기준값 JSON 또는 해시값 비교, SQL 기반 검사 |

---

## 📄 보안기능확인서 기재 예시

> 제품은 Backend(Gradle), Frontend(pnpm), Database 설정 정보를 기준으로 무결성 검사를 지원합니다.
> 각각의 주요 설정 및 산출물에 대해 SHA-256 해시값 또는 설정 기준값을 저장하고 있으며, 관리자는 CLI 또는 UI를 통해 수동으로 검사를 수행할 수 있습니다. 검사 결과는 감사 로그에 기록되며, 변경 감지 시 관리자 알림 또는 대응 조치가 이루어집니다.

---
