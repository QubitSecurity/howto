# HOWTO: dev → staging → live GitOps 동기화

## 개요
본 문서는 dev(d-gitlab)에서 개발 완료된 코드를
staging(s-gitops), live(gitops) 환경으로 안전하게 동기화하는 표준 절차를 설명합니다.

---

## 0️⃣ Git Repository 다운로드 & dev 최신 동기화 (작업 시작 지점)

> 모든 dev → staging → live 동기화 작업은
> “로컬에 dev 저장소를 받고, 최신 상태로 맞추는 것”에서 시작합니다.

staging(s-gitops)과 live(gitops)는
dev(d-gitlab)을 기준으로 동기화되는 대상이므로,
항상 dev 저장소를 먼저 로컬에 준비해야 합니다.

### 0-1. dev(d-gitlab) 저장소 다운로드 (처음 1회)

아래 중 하나를 사용합니다.

```bash
git clone git@gitlab.plura.internal:config/system.git
cd system
```

또는 SSH alias(d-gitlab)를 사용하는 경우:

```bash
git clone git@d-gitlab:config/system.git
cd system
```

이 시점에서의 상태:
- origin → dev(d-gitlab)
- origin/main → dev 기준 main 브랜치

확인:
```bash
git remote -v
git branch
```

### 0-2. (권장) WSL 기준 Git 기본 설정 (1회만)

```bash
git config --global core.autocrlf input
git config --global core.eol lf
git config --global core.safecrlf false
```

### 0-3. dev 최신을 항상 확실하게 가져오는 표준 방법

> git pull 대신 아래 방식을 표준으로 사용합니다.

```bash
git fetch origin
git reset --hard origin/main
git clean -fd
```

### 0-4. 최신 동기화 확인

```bash
git rev-parse HEAD
git rev-parse origin/main
```

두 값이 같으면 dev 최신 동기화 완료입니다.

---

이제 이 dev 최신 상태를 기준으로
staging(s-gitops), live(gitops)로 동기화를 진행합니다.
