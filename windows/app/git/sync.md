## HOWTO: dev → staging → live GitOps 동기화 운영 절차

## 개요

본 문서는 **dev(d-gitlab)** 에서 개발 완료된 코드를
**staging(s-gitops)**, 이후 **live(gitops)** 환경으로 **안전하게 동기화**하는 표준 운영 절차를 설명합니다.

특히 다음 상황을 모두 포함합니다.

* 히스토리가 꼬여 충돌이 대량 발생하는 경우
* Protected `main` 브랜치를 유지하면서 초기 동기화가 필요한 경우
* GitLab UI 충돌 해결이 실패하는 경우
* “한 번은 정리(reset)하고 이후는 정상 승격” 전략

---

## 저장소/역할 정의

| 환경      | GitLab   | 목적        |
| ------- | -------- | --------- |
| dev     | d-gitlab | 개발 기준 저장소 |
| staging | s-gitops | 검증/사전 배포  |
| live    | l-gitops   | 운영(실서비스)  |

SSH alias 예시 (`~/.ssh/config`):

```text
Host d-gitlab
  HostName d-gitlab.com
  User git
  IdentityFile ~/.ssh/id_ed25519

Host s-gitops
  HostName s-gitlab.com
  User git
  IdentityFile ~/.ssh/id_ed25519

Host l-gitops
  HostName l-gitlab.com
  User git
  IdentityFile ~/.ssh/id_ed25519
```

---

## 0️⃣ Git Repository 다운로드 (작업 시작 지점)

> **dev → staging → live 동기화 작업은 항상  
> ‘dev 저장소를 로컬에 다운로드(clone)하는 것’에서 시작합니다.**

모든 승격과 동기화는 **dev(d-gitlab)** 저장소의 코드를 기준으로 이루어집니다.  
따라서 먼저 **대상 Repository를 로컬에 clone**해야 합니다.

### 0-1. dev(d-gitlab) 저장소 clone

```bash
git clone git@gitlab.plura.internal:config/system.git
cd system
```

또는 SSH alias를 사용하는 경우:

```bash
git clone git@d-gitlab:config/system.git
cd system
```

이 디렉토리에서의 기본 상태는 다음과 같습니다.

* `origin` → **dev(d-gitlab)** 저장소
* `origin/main` → dev 기준 main 브랜치

```bash
git remote -v
git branch
```

---

### 0-2. 왜 dev 저장소를 먼저 clone 하는가?

* **dev가 모든 환경의 기준(Source of Truth)** 이기 때문입니다.
* staging(s-gitops)과 live(gitops)는
  dev에서 검증된 결과를 **받아들이는 대상**일 뿐,
  직접 개발하거나 기준이 되는 저장소가 아닙니다.

즉, 흐름은 항상 다음과 같습니다.

```
[로컬 작업 디렉토리]
        ↑
   git clone
        ↑
dev (d-gitlab)
```

이후에 이 dev 기준 코드를:

* staging(s-gitops)로 동기화하거나
* live(gitops)로 동기화하거나
* promote 브랜치를 만들어 MR로 승격

하게 됩니다.

---

### 0-3. 이후 작업 흐름 요약

dev 저장소를 clone 한 이후부터는 다음 절차를 따릅니다.

1. **dev → staging 동기화**

   * 초기에는 reset(강제 동기화) 방식
   * 이후에는 promote + MR 방식

2. **staging → live 동기화**

   * 운영 표준은 staging 검증 후 live 반영
   * 초기 정리 단계에서는 dev → live 직접 동기화도 가능

👉 이 모든 절차는 **이 문서의 1️⃣, 2️⃣, 3️⃣ 단계**에서 상세히 설명합니다.

---

## 1️⃣ dev → staging 동기화 (초기 정리 / 리셋 방식)

> staging에 과거 히스토리가 많아 충돌이 반복될 경우,
> **한 번은 staging `main`을 dev 기준으로 초기화**하는 것이 가장 안정적입니다.

### 1-1. staging 저장소 clone

```bash
git clone git@s-gitops:config/system.git s-system
cd s-system
```

> 이 디렉토리에서는
> `origin = s-gitops` 입니다.

---

### 1-2. staging main 백업 태그 생성 (필수)

```bash
git fetch origin
OLD=$(git rev-parse origin/main)
TAG="backup-s-gitops-main-$(date +%Y%m%d-%H%M%S)"
git tag "$TAG" "$OLD"
git push origin "$TAG"
```

👉 staging 기존 상태는 태그로 **영구 보존**됩니다.

---

### 1-3. dev 저장소를 remote로 추가

```bash
git remote add dev git@d-gitlab:config/system.git
git fetch dev main
```

---

### 1-4. staging main을 dev main으로 강제 동기화

⚠️ **전제 조건**

* s-gitops GitLab에서 `main` protected branch에 대해

  * *Maintainer만 force push*를 **일시적으로 허용**

```bash
git push --force-with-lease origin dev/main:main
```

---

### 1-5. 동기화 확인

```bash
git fetch origin
git rev-parse origin/main
git rev-parse dev/main
```

→ 해시가 같으면 **dev → staging 동기화 완료**

---

### 1-6. staging 보호 설정 원복 (중요)

* GitLab → Settings → Repository → Protected branches
* `main` → force push **다시 비활성화**

---

## 2️⃣ dev → live 동기화 (요청 시 직접 동기화)

> 요청에 따라 **dev를 바로 live로 동기화**할 수 있습니다.
> (운영 표준은 staging 경유이지만, 초기 정리 단계에서는 허용)

### 2-1. live 저장소를 remote로 추가

```bash
git remote add live git@gitops:config/system.git
git fetch live
```

---

### 2-2. live main 백업 태그 생성 (강력 권장)

```bash
OLD=$(git rev-parse live/main)
TAG="backup-gitops-main-$(date +%Y%m%d-%H%M%S)"
git tag "$TAG" "$OLD"
git push live "$TAG"
```

---

### 2-3. dev main → live main 강제 동기화

⚠️ **전제 조건**

* gitops GitLab에서 `main`에 대해

  * *Maintainer만 force push* **일시 허용**

```bash
git push --force-with-lease live dev/main:main
```

---

### 2-4. 동기화 확인

```bash
git fetch live
git rev-parse dev/main
git rev-parse live/main
```

→ 해시가 같으면 **dev → live 동기화 완료**

---

### 2-5. live 보호 설정 원복

* gitops GitLab에서 `main` force push 다시 OFF

---

## 3️⃣ 운영 표준 (권장 흐름, 이후부터)

초기 정리가 끝난 뒤에는 **아래 방식으로만 운영**합니다.

### 🔁 정상 승격 흐름

```
dev(main)
   ↓ promote 브랜치
staging(main)
   ↓ promote 브랜치
live(main)
```

### dev → staging (정상 승격)

```bash
REL="promote/$(date +%Y%m%d-%H%M%S)"
git push s-gitops origin/main:refs/heads/$REL
```

→ s-gitops GitLab에서 MR → main merge

### staging → live (정상 승격)

```bash
REL="promote/$(date +%Y%m%d-%H%M%S)"
git push gitops s-gitops/main:refs/heads/$REL
```

→ gitops GitLab에서 MR → main merge

---

## 4️⃣ 왜 이 방식이 정답인가

* 대량 충돌/리베이스 지옥 **근본 차단**
* Protected `main` 정책 유지
* 초기 1회만 강제 동기화, 이후는 MR 기반
* 모든 과거 상태는 **backup tag로 복구 가능**
* GitLab UI 충돌 해결 실패에도 흔들리지 않음

---

## 한 줄 요약

> **처음 한 번은 dev 기준으로 staging/live를 정리(reset)하고,
> 이후부터는 promote + MR 방식으로만 운영한다.**

---


