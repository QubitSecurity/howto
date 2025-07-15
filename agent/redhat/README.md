# 🔐 PLURA-XDR Secure License Registration Script

이 스크립트는 **PLURA-XDR 라이선스 키 등록**을 보다 안전하게 처리하기 위해 다음 보안 원칙을 따릅니다:

- **라이선스 키를 평문으로 메모리에 저장하지 않음**
- **Bash history에 명령어가 기록되지 않음**
- **출력에는 항상 `***`로 마스킹**
- **사용 직후 모든 민감 정보는 메모리에서 제거**

---

## 🛠️ 사용 방법

터미널에서 스크립트를 실행하면, 다음과 같은 단계를 거칩니다:

1. **암호화용 비밀번호 입력**  
   → 추후 복호화를 위한 키입니다.

2. **라이선스 키 입력**  
   → 입력한 키는 메모리에 저장하지 않고 바로 암호화됩니다.

3. **복호화용 비밀번호 입력**  
   → 복호화가 성공해야 실제 등록 명령이 수행됩니다.

4. **라이선스 등록 수행**  
   → `plura register` 명령이 내부에서 실행되며, 사용자에게는 `"***"`로 마스킹된 로그만 보여집니다.

---

## 📦 출력 예시

```text

curl -O https://repo.plura.io/v6/agent/install.sh

bash install.sh

bash plura_register_enc.sh

Enter encryption password:
Enter license key to encrypt:
Enter decryption password:
➡ Running: plura register "***"
[PLURA] 라이선스 등록 성공
```
