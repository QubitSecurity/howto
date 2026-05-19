# HOWTO: dev → staging → live GitOps 동기화 (`config/filter`)

## 개요

본 문서는 **dev(d-gitlab)** 의 `config/filter` Repository에 반영된 최신 코드를
**staging(s-gitops)** 과 **live(gitops)** 로 동기화하는 절차를 설명합니다.

```text
dev(d-gitlab) = 기준 저장소
staging(s-gitops) = 검증/사전 배포 저장소
live(gitops) = 운영 저장소
```

동기화 작업은 항상 **로컬 dev Repository 경로인 `~/filter`** 에서 시작합니다.

---

## 0️⃣ 저장소/경로 기준

| 구분 | 값 |
|---|---|
| dev GitLab | `d-gitlab` |
| staging GitLab | `s-gitops` |
| live GitLab | `gitops` |
| Repository | `config/filter` |
| 로컬 dev Repository | `~/filter` |
| 실제 WSL 경로 | `/home/joo/filter` |
| 기본 브랜치 | `main` |

> 중요: 이 문서의 Git 명령은 기본적으로 **`~/filter`** 에서 실행합니다.  
> `~/filter`는 dev(d-gitlab)의 `config/filter`를 clone한 로컬 Repository입니다.

---

## 1️⃣ SSH alias 확인

`~/.ssh/config`에 아래와 같이 alias가 있어야 합니다.

```text
Host d-gitlab
  HostName gitlab.plura.internal
  User git
  IdentityFile ~/.ssh/id_ed25519

Host s-gitops
  HostName s-gitops.plura.internal
  User git
  IdentityFile ~/.ssh/id_ed25519

Host gitops
  HostName gitops.plura.internal
  User git
  IdentityFile ~/.ssh/id_ed25519
```

접속 확인:

```bash
ssh -T d-gitlab
ssh -T s-gitops
ssh -T gitops
```

---

## 2️⃣ dev Repository를 로컬에 준비

아직 로컬에 `filter` Repository가 없다면 먼저 clone합니다.

```bash
cd ~
git clone git@d-gitlab:config/filter.git filter
cd ~/filter
```

또는 원본 GitLab 주소를 직접 사용할 수 있습니다.

```bash
cd ~
git clone git@gitlab.plura.internal:config/filter.git filter
cd ~/filter
```

정상 확인:

```bash
pwd
git remote -v
git branch
```

정상 예:

```text
/home/joo/filter

origin  git@d-gitlab:config/filter.git (fetch)
origin  git@d-gitlab:config/filter.git (push)
```

---

## 3️⃣ 작업 전 dev 최신 상태로 맞추기

staging/live로 동기화하기 전에, 로컬 dev Repository를 항상 최신 상태로 맞춥니다.

> `git pull` 대신 아래 3줄을 표준으로 사용합니다.

```bash
cd ~/filter
git fetch origin
git reset --hard origin/main
git clean -fd
```

최신 동기화 확인:

```bash
git rev-parse HEAD
git rev-parse origin/main
```

두 값이 같으면 로컬이 dev 최신 상태입니다.

---

## 4️⃣ staging / live remote 등록

로컬 dev Repository(`~/filter`)에 staging과 live remote를 추가합니다.

```bash
cd ~/filter

git remote add s-gitops git@s-gitops:config/filter.git 2>/dev/null || true
git remote add gitops git@gitops:config/filter.git 2>/dev/null || true

git remote -v
```

정상 예:

```text
origin    git@d-gitlab:config/filter.git (fetch)
origin    git@d-gitlab:config/filter.git (push)
s-gitops  git@s-gitops:config/filter.git (fetch)
s-gitops  git@s-gitops:config/filter.git (push)
gitops    git@gitops:config/filter.git (fetch)
gitops    git@gitops:config/filter.git (push)
```

---

## 5️⃣ dev → staging 동기화

### 5-1. staging main 백업 태그 생성

staging의 기존 `main` 상태를 백업 태그로 보존합니다.

```bash
cd ~/filter

git fetch s-gitops
OLD=$(git rev-parse s-gitops/main)
TAG="backup-s-gitops-main-$(date +%Y%m%d-%H%M%S)"

git tag "$TAG" "$OLD"
git push s-gitops "$TAG"
```

---

### 5-2. staging main을 dev main으로 강제 동기화

⚠️ 전제 조건:

- s-gitops GitLab에서 `main` protected branch에 대해
- Maintainer가 **force push를 일시적으로 허용**해야 합니다.
- 동기화 후 반드시 다시 비활성화합니다.

동기화 명령:

```bash
git push --force-with-lease s-gitops origin/main:main
```

---

### 5-3. staging 동기화 확인

```bash
git fetch s-gitops
git rev-parse origin/main
git rev-parse s-gitops/main
```

두 값이 같으면 **dev → staging 동기화 완료**입니다.

---

### 5-4. staging 보호 설정 원복

GitLab UI에서 아래를 원복합니다.

```text
s-gitops GitLab
→ Project Settings
→ Repository
→ Protected branches
→ main
→ Allow force push OFF
```

---

## 6️⃣ dev → live 동기화

초기 정리 단계에서는 dev main을 live main으로 직접 동기화할 수 있습니다.

> 운영 표준은 staging 검증 후 live 반영이지만,  
> live 저장소도 한 번 dev 기준으로 정리해야 할 때는 아래 절차를 사용합니다.

### 6-1. live main 백업 태그 생성

```bash
cd ~/filter

git fetch gitops
OLD=$(git rev-parse gitops/main)
TAG="backup-gitops-main-$(date +%Y%m%d-%H%M%S)"

git tag "$TAG" "$OLD"
git push gitops "$TAG"
```

---

### 6-2. live main을 dev main으로 강제 동기화

⚠️ 전제 조건:

- gitops GitLab에서 `main` protected branch에 대해
- Maintainer가 **force push를 일시적으로 허용**해야 합니다.
- 동기화 후 반드시 다시 비활성화합니다.

```bash
git push --force-with-lease gitops origin/main:main
```

---

### 6-3. live 동기화 확인

```bash
git fetch gitops
git rev-parse origin/main
git rev-parse gitops/main
```

두 값이 같으면 **dev → live 동기화 완료**입니다.

---

### 6-4. live 보호 설정 원복

GitLab UI에서 아래를 원복합니다.

```text
gitops GitLab
→ Project Settings
→ Repository
→ Protected branches
→ main
→ Allow force push OFF
```

---

## 7️⃣ 운영 표준: promote branch + MR 방식

초기 정리(reset)가 끝난 뒤에는 `main`에 직접 force push하지 않고,
promote 브랜치와 Merge Request를 사용합니다.

### 정상 승격 흐름

```text
dev(main)
   ↓ promote 브랜치
staging(main)
   ↓ promote 브랜치
live(main)
```

---

### 7-1. dev → staging 정상 승격

```bash
cd ~/filter

git fetch origin
git reset --hard origin/main
git clean -fd

REL="promote/$(date +%Y%m%d-%H%M%S)"
git push s-gitops origin/main:refs/heads/$REL
```

그 다음 s-gitops GitLab 웹 UI에서:

```text
Source branch: promote/YYYYMMDD-HHMMSS
Target branch: main
Create Merge Request
Review / Approve
Merge
```

---

### 7-2. staging → live 정상 승격

staging main에 Merge가 완료된 후, 그 staging main을 live로 승격합니다.

```bash
cd ~/filter

git fetch s-gitops

REL="promote/$(date +%Y%m%d-%H%M%S)"
git push gitops s-gitops/main:refs/heads/$REL
```

그 다음 gitops GitLab 웹 UI에서:

```text
Source branch: promote/YYYYMMDD-HHMMSS
Target branch: main
Create Merge Request
Review / Approve
Merge
```

---

## 8️⃣ 자주 발생하는 문제

### 8-1. `fetch first` 또는 `non-fast-forward` 에러

원격에 로컬에 없는 커밋이 있을 때 발생합니다.

초기 정리 단계라면:

```bash
git fetch origin
git reset --hard origin/main
git clean -fd
```

그 다음 다시 staging/live 동기화를 진행합니다.

정상 운영 단계라면 promote 브랜치를 새로 만들고 MR로 처리합니다.

---

### 8-2. Protected branch 때문에 force push가 막히는 경우

에러 예:

```text
You are not allowed to force push code to a protected branch
```

해결:

```text
GitLab UI
→ Settings
→ Repository
→ Protected branches
→ main
→ Allow force push ON
```

작업이 끝나면 반드시 다시 OFF 합니다.

---

### 8-3. GitLab UI에서 대량 충돌이 발생하는 경우

초기 정리 단계에서 staging/live 히스토리가 dev와 크게 다르면 대량 충돌이 발생할 수 있습니다.

이 경우:

1. 기존 main을 backup tag로 보존
2. Maintainer가 force push를 1회 허용
3. dev main으로 staging/live main을 재동기화
4. force push를 다시 금지
5. 이후부터 promote + MR 방식으로 운영

---

## 9️⃣ 최종 요약

### dev 최신화

```bash
cd ~/filter
git fetch origin
git reset --hard origin/main
git clean -fd
```

### dev → staging 초기 동기화

```bash
git fetch s-gitops
OLD=$(git rev-parse s-gitops/main)
TAG="backup-s-gitops-main-$(date +%Y%m%d-%H%M%S)"
git tag "$TAG" "$OLD"
git push s-gitops "$TAG"

git push --force-with-lease s-gitops origin/main:main
```

### dev → live 초기 동기화

```bash
git fetch gitops
OLD=$(git rev-parse gitops/main)
TAG="backup-gitops-main-$(date +%Y%m%d-%H%M%S)"
git tag "$TAG" "$OLD"
git push gitops "$TAG"

git push --force-with-lease gitops origin/main:main
```

### 이후 운영 표준

```bash
# dev → staging
REL="promote/$(date +%Y%m%d-%H%M%S)"
git push s-gitops origin/main:refs/heads/$REL

# staging → live
git fetch s-gitops
REL="promote/$(date +%Y%m%d-%H%M%S)"
git push gitops s-gitops/main:refs/heads/$REL
```

---

## 핵심 한 줄

> **초기에는 dev 기준으로 staging/live를 1회 정리하고, 이후에는 promote 브랜치와 MR로만 승격한다.**
