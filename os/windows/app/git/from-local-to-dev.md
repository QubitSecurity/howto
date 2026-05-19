# HOWTO: local → dev GitLab 업로드 절차 (`config/filter`)

## 개요

본 문서는 로컬에서 새로 만든 코드 또는 수정한 파일을 **dev GitLab(d-gitlab)** 의 `config/filter` Repository에 반영하는 절차를 설명합니다.

이 문서에서 가장 중요한 점은 **Git 명령을 실행하는 위치**와 **실제 filter 파일을 넣는 위치**가 다르다는 것입니다.

```text
Git Repository 루트        : /home/joo/filter
실제 filter 파일 경로      : /home/joo/filter/filter
```

즉,

- `git status`, `git add`, `git commit`, `git push`는 **항상 `/home/joo/filter`에서 실행**
- 새 filter 파일이나 수정 파일은 보통 **`/home/joo/filter/filter` 아래에 복사**

합니다.

---

## 전체 작업 흐름

```text
1. dev Repository를 로컬에 준비
2. dev 최신 상태로 동기화
3. 새 코드/수정 파일을 /home/joo/filter/filter 아래에 넣기
4. /home/joo/filter 로 이동
5. git status로 변경 확인
6. git add
7. git commit
8. git push origin main
9. dev GitLab 반영 확인
```

---

## 0️⃣ 작업 기준 경로

이 문서는 아래 경로를 기준으로 설명합니다.

| 구분 | 값 |
|---|---|
| dev GitLab | `d-gitlab` |
| Repository | `config/filter` |
| Git Repository 루트 | `~/filter` |
| 실제 Git 루트 경로 | `/home/joo/filter` |
| filter 파일 디렉터리 | `~/filter/filter` |
| 실제 filter 파일 경로 | `/home/joo/filter/filter` |
| 기본 브랜치 | `main` |
| 기본 remote | `origin` |

> 중요: `~/filter` 디렉터리 안에서 `origin`은 dev GitLab의 `config/filter` Repository를 의미합니다.

---

## 1️⃣ dev Repository를 로컬에 다운로드

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

정상 clone 여부 확인:

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

Repository 구조 예:

```text
/home/joo/
└── filter/                 ← Git Repository 루트
    ├── .git/               ← Git 저장소 정보
    ├── filter/             ← 실제 filter 파일 디렉터리
    └── 기타 파일/디렉터리
```

---

## 2️⃣ WSL Git 기본 설정

줄바꿈(CRLF/LF) 노이즈를 줄이기 위해 아래 설정을 1회 적용합니다.

```bash
git config --global core.autocrlf input
git config --global core.eol lf
git config --global core.safecrlf false
```

---

## 3️⃣ 작업 전 dev 최신 상태로 맞추기

로컬에 새 코드를 넣기 전에, 먼저 dev의 최신 상태를 가져옵니다.

> `git pull` 대신 아래 3줄을 표준으로 사용합니다.

```bash
cd ~/filter
git fetch origin
git reset --hard origin/main
git clean -fd
```

주의:

> 위 명령은 로컬 변경 사항을 삭제하고 dev 기준 최신 상태로 맞춥니다.  
> 따라서 새 코드를 복사하기 **전에만** 실행하세요.

최신 상태 확인:

```bash
git rev-parse HEAD
git rev-parse origin/main
```

두 값이 같으면 로컬이 dev 최신 상태입니다.

---

## 4️⃣ 새 코드 또는 수정 파일을 로컬 Repository에 넣기

dev 최신 상태를 준비한 뒤, 새 코드나 수정 파일을 **`~/filter/filter`** 아래의 정확한 경로에 넣습니다.

> 여기서 `~/filter`는 Git Repository 루트이고,  
> `~/filter/filter`는 실제 filter 파일이 위치하는 하위 디렉터리입니다.

---

### 4-1. WSL 내부 파일을 복사하는 경우

파일 1개를 실제 filter 디렉터리에 복사하는 예:

```bash
cp ./new-filter-file.json ~/filter/filter/
```

특정 하위 경로에 복사하는 예:

```bash
cp ./new-filter-file.json ~/filter/filter/<대상경로>/
```

디렉터리 단위 복사 예:

```bash
rsync -av ./new-filter-directory/ ~/filter/filter/<대상경로>/
```

---

### 4-2. Windows 다운로드 폴더에서 복사하는 경우

Windows의 `C:\Users\...` 경로는 WSL에서 `/mnt/c/Users/...`로 접근합니다.

파일 1개 복사 예:

```bash
cp /mnt/c/Users/<WindowsUser>/Downloads/new-filter-file.json ~/filter/filter/
```

디렉터리 단위 복사 예:

```bash
rsync -av /mnt/c/Users/<WindowsUser>/Downloads/filter/ ~/filter/filter/
```

실제 사용자명이 `joo`인 경우 예:

```bash
rsync -av /mnt/c/Users/joo/Downloads/filter/ ~/filter/filter/
```

> `<WindowsUser>`와 `<대상경로>`는 실제 환경에 맞게 바꿉니다.

---

## 5️⃣ Git 명령 실행 위치로 이동

`git add .`는 반드시 **Git Repository 루트 경로**에서 실행합니다.

```bash
cd ~/filter
pwd
```

정상 예:

```text
/home/joo/filter
```

아래 위치가 아닙니다.

```bash
cd ~/filter/filter
```

`~/filter/filter`는 실제 파일을 넣는 하위 디렉터리이며, 일반적인 Git 작업 위치로 사용하지 않습니다.

정확한 Git Repository 루트를 확인하려면 아래 명령을 사용합니다.

```bash
git rev-parse --show-toplevel
```

현재 위치가 하위 디렉터리라면 아래 명령으로 Git 루트로 이동할 수 있습니다.

```bash
cd "$(git rev-parse --show-toplevel)"
```

---

## 6️⃣ 변경 사항 확인

Repository 루트에서 변경 사항을 확인합니다.

```bash
cd ~/filter
git status
```

짧게 확인하려면:

```bash
git status --short
```

변경된 파일 목록만 보려면:

```bash
git diff --name-only
```

줄바꿈 노이즈인지 확인하려면:

```bash
git diff --ignore-cr-at-eol -- <파일경로> | head
```

출력이 없으면 실제 내용 변경 없이 줄바꿈 차이만 있는 경우입니다.

---

## 7️⃣ 변경 사항 선택 (`git add`)

### 전체 변경 사항을 올릴 경우

반드시 Repository 루트인 `~/filter`에서 실행합니다.

```bash
cd ~/filter
git add .
```

> `.`은 현재 디렉터리, 즉 `/home/joo/filter` 아래의 모든 변경 사항을 의미합니다.

### 실제 filter 디렉터리 변경만 올릴 경우

```bash
cd ~/filter
git add filter/
```

### 특정 파일만 올릴 경우

```bash
cd ~/filter
git add filter/<파일경로>
```

예:

```bash
cd ~/filter
git add filter/example.json
```

스테이징 확인:

```bash
git status --short
```

---

## 8️⃣ 로컬 commit 생성

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

그 다음 다시 commit 합니다.

```bash
git commit -m "Update filter configuration"
```

---

## 9️⃣ dev GitLab로 push

로컬 commit을 dev GitLab의 `main` 브랜치로 전송합니다.

```bash
git push origin main
```

---

## 🔟 dev GitLab 반영 확인

로컬과 dev 원격의 commit 해시가 같은지 확인합니다.

```bash
git fetch origin
git rev-parse HEAD
git rev-parse origin/main
```

두 값이 같으면 dev GitLab 반영이 완료된 것입니다.

GitLab 웹 UI에서도 `config/filter` Repository의 최신 commit 시간이 갱신되었는지 확인합니다.

---

## 1️⃣1️⃣ 자주 발생하는 문제와 대응

### 11-1. `Everything up-to-date`가 나오는데 파일이 안 올라간 경우

대부분 commit을 하지 않은 상태입니다.

확인:

```bash
cd ~/filter
git status
```

해결:

```bash
cd ~/filter
git add .
git commit -m "Update filter configuration"
git push origin main
```

---

### 11-2. push가 거절되는 경우

다른 사람이 dev에 먼저 push했을 수 있습니다.

```bash
cd ~/filter
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

### 11-3. 줄바꿈(CRLF/LF) 때문에 파일이 수정된 것처럼 보이는 경우

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

## 최종 요약: 로컬 코드를 dev에 올리는 전체 순서

```bash
# 1. Repository 루트로 이동
cd ~/filter

# 2. 작업 전 dev 최신화
git fetch origin
git reset --hard origin/main
git clean -fd

# 3. 새 코드 복사 또는 파일 수정
# 예: rsync -av /mnt/c/Users/joo/Downloads/filter/ ~/filter/filter/

# 4. Repository 루트로 이동
cd ~/filter

# 5. 변경 사항 확인
git status

# 6. 변경 사항 선택
git add .

# 또는 filter 디렉터리만 올릴 경우
# git add filter/

# 7. commit 생성
git commit -m "Update filter configuration"

# 8. dev GitLab로 push
git push origin main

# 9. 반영 확인
git fetch origin
git rev-parse HEAD
git rev-parse origin/main
```

> 로컬에서 작업한 내용을 dev에 반영하려면 반드시 `add → commit → push` 세 단계를 모두 수행해야 합니다.
