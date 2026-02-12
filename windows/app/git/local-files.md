## 🎯 전제 요약

* 작업 위치:

  ```
  /home/<ubuntu-user>/work/
  ```
* 현재 데이터 위치는 보통 이 중 하나:

  1. Windows 폴더 (C:, D:\ 등)
  2. 이미 Ubuntu(WSL) 어딘가에 있는 파일
  3. Git 저장소

---

## 1️⃣ Windows → Ubuntu(`/home/.../work`)로 옮기기 (가장 흔함)

### 방법 1: **파일 탐색기 드래그 앤 드롭 (초보자도 OK)**

1. Windows 탐색기 열기
2. 주소창에 입력:

   ```
   \\wsl$\Ubuntu-24.04\home\<ubuntu-user>\work
   ```
3. Windows 쪽 파일/폴더를 **그냥 드래그해서 복사**

✅ 장점

* 가장 직관적
* 실수 적음
* 텍스트/스크립트 파일 안전

⚠️ 주의

* 복사(Ctrl+C / Ctrl+V) 사용
* 이동(Ctrl+X)보다는 **복사 후 정리**

---

### 방법 2: **Ubuntu에서 cp / rsync 사용 (대량 파일 권장)**

Windows 파일은 Ubuntu에서 이렇게 보입니다:

```
/mnt/c/Users/<windows-user>/...
```

예시:

```bash
mkdir -p ~/work/filter

cp -r /mnt/c/Users/eliot/Desktop/filter ~/work/
```

또는 **대량/중요 데이터는 rsync (강력 추천)**

```bash
rsync -avh --progress /mnt/c/Users/eliot/Desktop/filter/ ~/work/filter/
```

✔ 권한/속성 안정
✔ 중간에 끊겨도 재시도 가능
✔ diff 확인 쉬움

---

## 2️⃣ Ubuntu 내부 경로 → `/home/.../work` 이동

이미 Ubuntu 어딘가에 파일이 있다면:

```bash
mv ~/Downloads/filter ~/work/
```

또는 복사:

```bash
cp -r ~/Downloads/filter ~/work/
```

---

## 3️⃣ Git 저장소라면 “옮기지 말고 다시 clone”이 정답

이미 Windows에 Git 저장소가 있다면
👉 **복사하지 말고 Ubuntu에서 다시 clone** 하세요.

```bash
cd ~/work
git clone git@d-gitlab:config/filter.git
```

이게 가장 깨끗합니다.

---

## 4️⃣ 권한 / 실행 비트 정리 (중요)

Windows에서 복사한 후에는 **반드시 한 번 실행**

```bash
cd ~/work/filter
chmod +x *.sh
```

필요 시 전체 정리:

```bash
find . -type f -name "*.sh" -exec chmod 755 {} \;
```

---

## 5️⃣ 줄바꿈(CRLF) 정리 (한 번만)

```bash
git config --global core.autocrlf input
git config --global core.eol lf
```

이미 깨졌다면:

```bash
git add --renormalize .
git commit -m "normalize line endings"
```

---

## 6️⃣ 제대로 옮겨졌는지 체크리스트

```bash
cd ~/work/filter
ls
git status
```

정상 예:

* 파일 정상 표시
* 의미 없는 변경(diff) 없음
* 실행 스크립트 에러 없음

---

## 🧠 실무 추천 조합 (베스트)

| 상황      | 방법                     |
| ------- | ---------------------- |
| 몇 개 파일  | Windows 탐색기 → `\\wsl$` |
| 대량 파일   | `rsync -avh`           |
| Git 저장소 | Ubuntu에서 `git clone`   |
| 운영 스크립트 | Ubuntu 홈에서만 작업         |

---

## 🏁 한 줄 요약

> **Windows 데이터는 복사해서 `/home/<ubuntu-user>/work`에 두고,
> Git 작업은 반드시 Ubuntu에서 한다.**

---
