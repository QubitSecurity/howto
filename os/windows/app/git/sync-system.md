# HOWTO: AI 경로 dev → staging → live 동기화

## 개요

본 문서는 AI 관련 경로를 dev, staging, live 환경에 순서대로 동기화하는 절차를 설명합니다.

대상 경로는 다음 2개입니다.

```text
ai/prompt/global
ai/use/page
```

기존 문서의 핵심 명령은 아래 3종류입니다.

```bash
sh ./api/d-git-sync.sh ai/prompt/global
sh ./api/s-git-sync.sh ai/prompt/global
sh ./api/git-sync.sh ai/prompt/global
```

이 문서는 위 명령을 **어느 경로에서, 어떤 순서로 실행해야 하는지** 명확히 정리합니다.

---

## 0️⃣ 작업 기준 경로

이 문서의 명령은 반드시 **`api/` 디렉터리와 `ai/` 디렉터리가 함께 보이는 Repository 루트**에서 실행합니다.

예상 구조:

```text
<repository-root>/
├── api/
│   ├── d-git-sync.sh
│   ├── s-git-sync.sh
│   └── git-sync.sh
├── ai/
│   ├── prompt/
│   │   └── global/
│   └── use/
│       └── page/
└── ...
```

현재 위치 확인:

```bash
pwd
ls -la
ls -la api
ls -la ai
```

`./api/d-git-sync.sh` 파일이 보이지 않으면 잘못된 위치입니다.

---

## 1️⃣ dev 동기화

먼저 dev(d-gitlab)에 AI 경로를 동기화합니다.

```bash
sh ./api/d-git-sync.sh ai/prompt/global
sleep 1

sh ./api/d-git-sync.sh ai/use/page
sleep 1
```

확인할 내용:

- 명령이 오류 없이 완료되는지
- `ai/prompt/global` 반영 여부
- `ai/use/page` 반영 여부

---

## 2️⃣ staging 동기화

dev 반영이 정상임을 확인한 뒤 staging(s-gitops)에 동기화합니다.

```bash
sh ./api/s-git-sync.sh ai/prompt/global
sleep 1

sh ./api/s-git-sync.sh ai/use/page
sleep 1
```

확인할 내용:

- staging GitLab 또는 staging 배포 환경에서 변경 사항이 보이는지
- 오류 메시지가 없는지

---

## 3️⃣ live 동기화

staging 검증이 끝난 뒤 live(gitops)에 동기화합니다.

```bash
sh ./api/git-sync.sh ai/prompt/global
sleep 1

sh ./api/git-sync.sh ai/use/page
sleep 1
```

확인할 내용:

- live GitLab 또는 live 배포 환경에서 변경 사항이 보이는지
- 오류 메시지가 없는지

---

## 4️⃣ 전체 실행 순서 요약

아래 순서로 실행합니다.

```bash
# 1. dev 동기화
sh ./api/d-git-sync.sh ai/prompt/global
sleep 1

sh ./api/d-git-sync.sh ai/use/page
sleep 1

# 2. staging 동기화
sh ./api/s-git-sync.sh ai/prompt/global
sleep 1

sh ./api/s-git-sync.sh ai/use/page
sleep 1

# 3. live 동기화
sh ./api/git-sync.sh ai/prompt/global
sleep 1

sh ./api/git-sync.sh ai/use/page
sleep 1
```

---

## 5️⃣ 실행 전 체크리스트

실행 전 아래를 확인합니다.

```bash
pwd
test -f ./api/d-git-sync.sh && echo "OK: d-git-sync.sh"
test -f ./api/s-git-sync.sh && echo "OK: s-git-sync.sh"
test -f ./api/git-sync.sh && echo "OK: git-sync.sh"

test -d ./ai/prompt/global && echo "OK: ai/prompt/global"
test -d ./ai/use/page && echo "OK: ai/use/page"
```

모두 `OK`가 나오면 실행 위치가 맞습니다.

---

## 6️⃣ 자주 발생하는 문제

### 6-1. `No such file or directory`가 나오는 경우

대부분 실행 위치가 잘못된 경우입니다.

아래 명령으로 Repository 루트로 이동한 뒤 다시 실행합니다.

```bash
cd <repository-root>
ls -la api
ls -la ai
```

---

### 6-2. dev는 됐는데 staging/live가 안 되는 경우

아래 순서를 다시 확인합니다.

```text
dev 동기화 성공
→ staging 동기화 실행
→ staging 확인
→ live 동기화 실행
→ live 확인
```

staging 확인 전 live를 먼저 실행하지 않습니다.

---

## 핵심 한 줄

> **AI 경로 동기화는 Repository 루트에서 `dev → staging → live` 순서로 실행한다.**
