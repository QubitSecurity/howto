## ✅ 무결성 검사 방안 (패키지 관리 기준: **Gradle / pnpm**)

### 1. **무결성 검사 목적**

* 제품의 핵심 실행 파일 및 설정값뿐 아니라,
* 패키지 의존성과 빌드 결과물도 **정상성과 변경 여부를 식별**할 수 있어야 함.

---

### 2. **Backend (Gradle 기반 Java/Kotlin 등)**

#### 📌 대상

* `build.gradle`, `settings.gradle`, `gradle.properties`
* `build/libs/*.jar`, `config/*.yml` 등
* `.gradle` 캐시 디렉토리 제외

#### 📌 무결성 관리 방법

* 주요 파일에 대해 **SHA-256 해시값 생성 및 기준값 보관**
* Git으로 버전 관리되므로 commit hash 기반 정합성 검증도 가능
* 빌드된 `.jar` 파일은 배포 전/후 해시 비교 가능

#### ✅ 예시 스크립트 (bash)

```bash
sha256sum build.gradle settings.gradle build/libs/app.jar > integrity-backend.txt
```

---

### 3. **Frontend (pnpm 기반 React)**

#### 📌 대상 파일

* `package.json`
* `pnpm-lock.yaml`
* `dist/` 또는 `build/` 디렉토리의 정적 산출물
* `node_modules/`는 검사 대상에서 제외됨 (재현 가능성 확보됨)

#### 📌 무결성 관리 방법

* **`pnpm-lock.yaml`** 파일은 의존성 정확도 및 무결성의 핵심 파일입니다.
* pnpm은 자체적으로 모든 패키지의 해시 정보를 `lockfile`에 기록하며,
  `pnpm install --frozen-lockfile` 옵션을 통해 변경 없이 설치 가능.
* 빌드된 결과물(`dist/`)의 해시값을 기준으로 무결성 비교 가능

#### ✅ 예시 명령어 (무결성 기준값 저장)

```bash
sha256sum package.json pnpm-lock.yaml dist/* > integrity-frontend.txt
```

---

### 4. **무결성 검사 자동화 예 (간단 스크립트)**

```bash
#!/bin/bash
echo "[Frontend Integrity Check]"
sha256sum -c integrity-frontend.txt
```

---

### 5. **전체 무결성 검사 요약**

| 구분       | 대상 파일                                      | 무결성 기준 관리 방식                   |
| -------- | ------------------------------------------ | ------------------------------ |
| Backend  | `build.gradle`, `*.jar`, 설정 파일 등           | SHA-256 해시 비교                  |
| Frontend | `package.json`, `pnpm-lock.yaml`, `dist/*` | SHA-256 해시 비교 및 lockfile 기반 검증 |
| 공통       | 검사 결과 로그, 관리자 수동 실행 가능                     | CLI 또는 UI 제공, 결과 감사 로그 기록      |

---

### 6. 📄 보안기능확인서 기재 예시

> 프론트엔드는 pnpm을 사용하여 패키지를 관리하며, `pnpm-lock.yaml` 파일을 기준으로 의존성 무결성을 확인할 수 있습니다. 주요 설정 및 빌드 결과물에 대해서는 SHA-256 해시값을 기준으로 무결성 검사를 수행하며, 관리자는 CLI 또는 UI를 통해 수동으로 검사를 실행할 수 있습니다. 검사 결과는 로그로 기록되며, 변경 감지 시 관리자 알림 또는 대응 조치가 이루어집니다.

---
