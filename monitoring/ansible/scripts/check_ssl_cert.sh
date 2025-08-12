#!/bin/bash

# ✅ 설정 영역
DOMAIN=$1
PORT=${2:-443}
WARNING_DAYS=30
MAIL_RECIPIENT="plura@qubitsec.com"
LOG_FILE="/var/log/check_ssl_cert.log"

DATE_NOW=$(date +%s)
CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")

if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 <domain> [port]"
    exit 1
fi

# 🔍 SSL 인증서 만료일 가져오기
EXPIRY_DATE=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:$PORT" 2>/dev/null \
    | openssl x509 -noout -enddate | cut -d= -f2)

if [ -z "$EXPIRY_DATE" ]; then
    echo "$CURRENT_TIME | ❌ Failed to retrieve SSL certificate for $DOMAIN" | tee -a "$LOG_FILE"
    echo -e "[ALERT] SSL 인증서 확인 실패\n도메인: $DOMAIN\n시간: $CURRENT_TIME" \
        | mail -s "[ALERT] SSL 인증서 확인 실패 - $DOMAIN" "$MAIL_RECIPIENT"
    exit 2
fi

# 📅 날짜 비교
EXPIRY_DATE_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
DAYS_LEFT=$(( (EXPIRY_DATE_EPOCH - DATE_NOW) / 86400 ))

# 📝 로그 기록
echo "$CURRENT_TIME | ✅ Domain: $DOMAIN | Expiry: $EXPIRY_DATE | Days left: $DAYS_LEFT" | tee -a "$LOG_FILE"

# ⚠️ 경고 조건
if [ "$DAYS_LEFT" -le "$WARNING_DAYS" ]; then
    echo -e "[ALERT] SSL 인증서 만료 임박\n도메인: $DOMAIN\n만료일: $EXPIRY_DATE\n남은 일수: $DAYS_LEFT" \
        | mail -s "[ALERT] SSL 인증서 $DAYS_LEFT일 남음 - $DOMAIN" "$MAIL_RECIPIENT"
fi

exit 0
