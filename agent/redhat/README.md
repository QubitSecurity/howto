# 🔐 PLURA-XDR Secure License Registration Script

이 스크립트는 **PLURA-XDR 라이선스 키 등록**을 보다 안전하게 처리하기 위해 다음 보안 원칙을 따릅니다:

- **라이선스 키를 평문으로 메모리에 저장하지 않음**
- **Bash history에 명령어가 기록되지 않음**
- **출력에는 항상 `***`로 마스킹**
- **사용 직후 모든 민감 정보는 메모리에서 제거**

---

## 🛠️ 사용 방법

스크립트를 실행하면 다음 순서로 진행됩니다:

1. **암호화용 비밀번호 입력**  
   → 추후 복호화를 위한 비밀번호입니다.

2. **라이선스 키 입력**  
   → 입력된 키는 메모리에 저장하지 않고 즉시 암호화됩니다.

3. **복호화용 비밀번호 입력**  
   → 정확히 입력해야만 복호화가 성공하고 등록이 진행됩니다.

4. **라이선스 등록 수행**  
   → `plura register` 명령 실행. 출력은 `"***"`로 마스킹됩니다.

---

## 📦 출력 예시 흐름

```bash
curl -O https://repo.plura.io/v6/agent/install.sh
bash install.sh

bash plura_register_enc.sh
````
설치가 완료되면 아래 명령을 통해 정상 설치 여부를 확인할 수 있습니다.

```bash
/usr/local/sbin/plurad -version
```

---


```text
Enter encryption password:
Enter license key to encrypt:
Enter decryption password:
➡ Running: plura register "***"
[PLURA] 라이선스 등록 성공
```

---

