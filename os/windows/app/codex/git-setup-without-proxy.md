# Git 설정 가이드 - Proxy 설정이 없는 경우

이 문서는 일반 인터넷 환경에서, 로컬 작업을 GitHub private 저장소에 올리고 다른 장소에서도 이어서 작업할 수 있도록 Git을 설정하는 방법을 정리한 문서입니다.

## 1. Git 설치

`Git for Windows` 를 설치합니다.

- 다운로드: [https://git-scm.com/download/win](https://git-scm.com/download/win)

설치 중 추천 옵션:

- `Windows Explorer integration`: 켜기
- `Open Git Bash here`: 켜기
- `Open Git GUI here`: 꺼도 됨
- `Git LFS (Large File Support)`: 켜기
- `Associate .git* configuration files with the default text editor`: 켜기
- `Associate .sh files to be run with Bash`: 켜기
- `Add a Git Bash Profile to Windows Terminal`: Windows Terminal 사용 시 켜기 추천
- `Scalar`: 꺼도 됨

다음 화면에서 권장값:

- Default editor: 익숙한 편집기, 모르면 `Visual Studio Code`
- PATH: `Git from the command line and also from 3rd-party software`
- Line ending: `Checkout Windows-style, commit Unix-style line endings`
- Credential helper: 기본값 유지

## 2. Git 사용자 정보 설정

PowerShell에서 한 번만 설정합니다.

```powershell
git config --global user.name "qubitsec"
git config --global user.email "qubit3d@gmail.com"
git config --global init.defaultBranch main
```

확인:

```powershell
git config --global --get user.name
git config --global --get user.email
git config --global --get init.defaultBranch
```

## 3. GitHub에서 private 저장소 만들기

GitHub 웹사이트에서 새 저장소를 생성합니다.

- Repository name: `quark`
- Visibility: `Private`
- `README`, `.gitignore`, `license`: 처음에는 체크하지 않는 것을 추천

예시 주소:

```text
https://github.com/qubitsec/quark.git
```

## 4. 로컬 프로젝트 시작

작업 폴더를 만들고 Git 저장소로 초기화합니다.

```powershell
mkdir C:\git\quark
cd C:\git\quark
git init
```

테스트용 파일 하나를 만든 뒤 첫 커밋을 합니다.

```powershell
"# quark" | Out-File -Encoding utf8 README.md
git add .
git commit -m "Initial commit"
```

## 5. GitHub 저장소 연결

원격 저장소를 `origin` 으로 등록합니다.

```powershell
git remote add origin https://github.com/qubitsec/quark.git
git branch -M main
```

확인:

```powershell
git remote -v
```

## 6. 첫 push와 인증

private 저장소라고 해서 반드시 토큰을 미리 만들 필요는 없습니다. 보통은 `Git Credential Manager` 가 브라우저 인증을 통해 처리합니다.

아래 명령을 실행합니다.

```powershell
git push -u origin main
```

처음 실행 시 보통 이런 흐름으로 진행됩니다.

1. 브라우저 인증 안내가 표시됨
2. `Sign in with your browser` 선택
3. GitHub 계정 로그인
4. 권한 승인
5. 인증 정보 저장
6. push 완료

성공 예시:

```text
To https://github.com/qubitsec/quark.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```

## 7. 이후 반복 작업

평소 작업 후에는 아래 순서만 반복하면 됩니다.

```powershell
cd C:\git\quark
git add .
git commit -m "작업 내용"
git push
```

다른 PC에서 이어서 작업:

```powershell
git clone https://github.com/qubitsec/quark.git
git pull
```

## 8. 문제 해결

`not a git repository` 오류:

- 현재 폴더에 `.git` 이 없다는 뜻입니다.
- `git init` 을 먼저 하거나, 기존 저장소라면 `git clone` 으로 받아와야 합니다.

`Failed to connect to github.com port 443` 오류:

- 네트워크 또는 보안 프로그램 문제일 수 있습니다.
- 브라우저에서 GitHub 접속 여부를 먼저 확인합니다.
- 회사망이나 VPN 환경이면 프록시 설정이 필요한지 점검합니다.

## 9. 핵심 요약

프록시가 없는 일반 환경에서는 아래 순서로 진행하면 됩니다.

1. Git 설치
2. `user.name`, `user.email`, `main` 설정
3. GitHub private 저장소 생성
4. 로컬에서 `git init`
5. `git remote add origin ...`
6. `git push -u origin main`
7. 브라우저 인증 완료
