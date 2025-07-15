#!/bin/bash

# 🔐 1. 히스토리 기록 방지
set +o history

# ✅ 2. 암호화용 키 입력
read -s -p "Enter encryption password: " ENCRYPTION_PASSWORD
echo ""

# ✅ 3. 라이선스 키 입력 → 바로 암호화 후 ENCRYPTED_KEY 변수에 저장
read -s -p "Enter license key to encrypt: " PLAINTEXT_LICENSE_KEY
echo ""

# 암호화 수행 (base64 포함)
ENCRYPTED_KEY=$(echo -n "$PLAINTEXT_LICENSE_KEY" | openssl enc -aes-256-cbc -a -salt -pass pass:"$ENCRYPTION_PASSWORD" 2>/dev/null)

# 즉시 메모리에서 평문 제거
unset PLAINTEXT_LICENSE_KEY
unset ENCRYPTION_PASSWORD

# ✅ 4. 복호화용 키 재입력
read -s -p "Enter decryption password: " DECRYPTION_PASSWORD
echo ""

# 복호화 시도
LICENSE_KEY=$(echo "$ENCRYPTED_KEY" | openssl enc -aes-256-cbc -d -a -pass pass:"$DECRYPTION_PASSWORD" 2>/dev/null)

# 복호화 성공 여부 확인
if [[ -z "$LICENSE_KEY" ]]; then
  echo "❌ Decryption failed. Please check your password."
  unset ENCRYPTED_KEY
  unset DECRYPTION_PASSWORD
  exit 1
fi

# ✅ 5. 마스킹된 메시지 출력 (실제 평문은 출력하지 않음)
echo "➡ Running: plura register \"***\""

# ✅ 6. 실제 등록 명령 실행
plura register "$LICENSE_KEY"

# ✅ 7. 민감 정보 모두 삭제
unset LICENSE_KEY
unset ENCRYPTED_KEY
unset DECRYPTION_PASSWORD

# ✅ 8. 히스토리 복원
set -o history
