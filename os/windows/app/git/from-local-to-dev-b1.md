# HOWTO: local → dev GitLab 업로드 절차 (`config/filter`)

## 개요

본 문서는 로컬에서 수정하거나 새로 만든 코드를 **dev GitLab(d-gitlab)** 의 `config/filter` Repository에 반영하는 절차를 설명합니다.

작업 흐름은 다음과 같습니다.

```text
dev(d-gitlab) 최신 다운로드
        ↓
로컬에서 파일 추가/수정
        ↓
git add
        ↓
git commit
        ↓
git push origin main
        ↓
dev GitLab 반영 완료
```

---

## 0️⃣ 작업 기준 경로

이 문서에서는 다음 경로를 기준으로 설명합니다.

| 구분 | 값 |
|---|---|
| dev GitLab | `d-gitlab` |
| Repository | `config/filter` |
| 로컬 작업 디렉터리 | `~/filter` |
| 실제 WSL 경로 | `/home/joo/filter` |
| 기본 브랜치 | `main` |
| 기본 remote | `origin` |

> `~/filter` 디렉터리에서 `origin`은 dev GitLab의 `config/filter` Repository를 의미합니다.

---

## 1️⃣ dev Repository 다운로드 또는 최신화

### 1-1. 처음 한 번만 clone

아직 로컬에 `filter` Repository가 없다면 먼저 다운로드합니다.

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

확인:

```bash
git remote -v
git branch
```

정상 예:

```text
origin  git@d-gitlab:config/filter.git (fetch)
origin  git@d-gitlab:config/filter.git (push)
```

---

### 1-2. WSL Git 기본 설정

줄바꿈(CRLF/LF) 노이즈를 줄이기 위해 아래 설정을 1회 적용합니다.

```bash
git config --global core.autocrlf input
git config --global core.eol lf
git config --global core.safecrlf false
```

---

### 1-3. dev 최신 상태로 맞추기

`git pull` 대신 아래 3줄을 표준으로 사용합니다.

```bash
cd ~/filter
git fetch origin
git reset --hard origin/main
git clean -fd
```

> ⚠️ 주의: 위 명령은 로컬 변경 사항을 삭제하고 dev 기준 최신 상태로 맞춥니다.  
> 새 코드를 복사하기 전, 작업 시작 시점에 실행하세요.

최신 동기화 확인:

```bash
git rev-parse HEAD
git rev-parse origin/main
```

두 값이 같으면 로컬이 dev 최신 상태입니다.

---

## 2️⃣ 새 코드 또는 수정 파일을 로컬 Repository에 넣기

dev 최신 상태를 준비한 후, 새 코드나 수정 파일을 `~/filter` 아래의 정확한 경로에 넣습니다.

### 2-1. WSL 내부 파일을 복사하는 경우

예:

```bash
cp ./new-filter-file.json ~/filter/<대상경로>/
```

또는 디렉터리 단위 복사:

```bash
rsync -av ./new-filter-directory/ ~/filter/<대상경로>/
```

---

### 2-2. Windows 다운로드 폴더에서 복사하는 경우

Windows의 `C:\Users\...` 경로는 WSL에서 `/mnt/c/Users/...`로 접근합니다.

예:

```bash
cp /mnt/c/Users/<WindowsUser>/Downloads/new-filter-file.json ~/filter/<대상경로>/
```

디렉터리 단위 복사 예:

```bash
rsync -av /mnt/c/Users/<WindowsUser>/Downloads/filter/ ~/filter/
```

> `<WindowsUser>`와 `<대상경로>`는 실제 환경에 맞게 바꿉니다.

---

### 2-3. 작업 위치 확인

항상 Repository 루트에서 작업합니다.

```bash
cd ~/filter
pwd
```

정상 예:

```text
/home/joo/filter
```

---

## 3️⃣ 변경 사항 확인

파일을 넣거나 수정한 뒤 변경 사항을 확인합니다.

```bash
cd ~/filter
git status
```

간단히 파일 목록만 보려면:

```bash
git status --short
git diff --name-only
```

줄바꿈 노이즈인지 확인하려면:

```bash
git diff --ignore-cr-at-eol -- <파일경로> | head
```

출력이 없으면 실제 내용 변경 없이 줄바꿈 차이만 있는 경우입니다.

---

## 4️⃣ 변경 사항 선택 (`git add`)

전체 변경 사항을 올릴 경우:

```bash
git add .
```

특정 파일만 올릴 경우:

```bash
git add <파일경로>
```

예:

```bash
git add filter/example.json
```

스테이징 확인:

```bash
git status --short
```

---

## 5️⃣ 로컬 commit 생성

변경 내용을 로컬 Git 이력에 기록합니다.

```bash
git commit -m "Update filter configuration"
```

예:

```bash
git commit -m "Add new filter rules"
```

Git 사용자 정보가 없다는 오류가 나오면 아래를 먼저 설정합니다.

```bash
git config --global user.name "Eliot Shin"
git config --global user.email "joo@qubitsec.com"
```

---

## 6️⃣ dev GitLab로 push

로컬 commit을 dev GitLab의 `main` 브랜치로 전송합니다.

```bash
git push origin main
```

정상적으로 올라갔는지 확인합니다.

```bash
git fetch origin
git rev-parse HEAD
git rev-parse origin/main
```

두 값이 같으면 dev GitLab 반영이 완료된 것입니다.

---

## 7️⃣ 자주 발생하는 문제와 대응

### 7-1. `Everything up-to-date`가 나오는데 파일이 안 올라간 경우

대부분 commit을 하지 않은 상태입니다.

확인:

```bash
git status
```

해결:

```bash
git add .
git commit -m "Update filter configuration"
git push origin main
```

---

### 7-2. push가 거절되는 경우

다른 사람이 dev에 먼저 push했을 수 있습니다.

```bash
git fetch origin
git rebase origin/main
git push origin main
```

충돌이 나면 충돌 파일을 수정한 뒤:

```bash
git add .
git rebase --continue
git push origin main
```

---

### 7-3. 줄바꿈(CRLF/LF) 때문에 파일이 수정된 것처럼 보이는 경우

내용 변경 여부를 확인합니다.

```bash
git diff --ignore-cr-at-eol -- <파일경로> | head
```

실제 내용 변경이 없다면 dev 최신 상태로 다시 맞춥니다.

```bash
git fetch origin
git reset --hard origin/main
git clean -fd
```

---

## 8️⃣ 최종 요약

로컬에서 새 코드를 dev로 올리는 기본 흐름은 다음과 같습니다.

```bash
cd ~/filter

# 작업 전 dev 최신화
git fetch origin
git reset --hard origin/main
git clean -fd

# 새 코드 복사 또는 수정 후
git status
git add .
git commit -m "Update filter configuration"
git push origin main

# 확인
git fetch origin
git rev-parse HEAD
git rev-parse origin/main
```

> 로컬에서 작업한 내용을 dev에 반영하려면 반드시 `add → commit → push` 세 단계를 모두 수행해야 합니다.
