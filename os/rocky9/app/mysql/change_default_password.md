MySQL의 **기본(root) 패스워드 변경 방법**은 아래와 같습니다. **일반적인 Linux 환경에서 root 패스워드를 안전하게 변경하는 표준 절차**입니다.

---

## ✅ 1. 현재 root 비밀번호로 로그인

```bash
mysql -u root -p
```

→ 비밀번호를 입력하면 MySQL 셸로 진입합니다.

---

## ✅ 2. root 사용자 비밀번호 변경

MySQL 5.7 이상 또는 8.0 기준으로는 다음 명령을 사용합니다:

```sql
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '새로운_비밀번호';
FLUSH PRIVILEGES;
```

> 🔒 **보안 주의**: `'새로운_비밀번호'`는 복잡한 비밀번호로 설정하시고, `'` (작은 따옴표)로 감싸야 합니다.

---

## ✅ 3. 종료

```sql
exit;
```

---

## 🔧 root 비밀번호를 잊었을 경우 (비상 복구)

1. MySQL 서비스를 안전모드로 시작 (비밀번호 인증 없이)

```bash
sudo systemctl stop mysql

sudo mysqld_safe --skip-grant-tables &
```

2. 새로운 터미널에서 root로 접속 (비밀번호 없이 가능)

```bash
mysql -u root
```

3. 비밀번호 변경

```sql
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '새로운_비밀번호';
```

4. MySQL 재시작

```bash
sudo systemctl restart mysql
```

---

## 📝 확인

비밀번호 변경 후 다시 로그인해 봅니다:

```bash
mysql -u root -p
```

---

## 📄 정리 문장 (보안기능확인서 예시용)

> 제품은 MySQL의 root 계정에 대해 관리자에 의한 비밀번호 변경을 지원합니다.
> `ALTER USER` 명령을 통해 비밀번호를 안전하게 변경할 수 있으며, 변경 후 권한 적용을 위해 `FLUSH PRIVILEGES` 명령이 수행됩니다. 비밀번호 변경은 감사 로그 또는 명령어 히스토리에 기록되며, 초기 설치 후에는 반드시 강제 변경을 요구합니다.

---
