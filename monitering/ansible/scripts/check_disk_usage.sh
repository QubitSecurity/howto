#!/bin/bash

LOG_TAG="disk_check"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

SCRIPT_DIR=$(dirname "$(realpath "$0")")

# 로그 파일 설정
LOG_FILE="$SCRIPT_DIR/check_disk_usage_${1//%/percent}.log"
DEBUG_LOG="$SCRIPT_DIR/debug.log"
MAIL_RECIPIENT="admin@example.com"  # ← 여기 수신자 이메일 주소로 수정하세요

# 로깅 함수
log_debug() {
    echo "$TIMESTAMP | DEBUG | $1" >> "$DEBUG_LOG"
}

log_info() {
    echo "$TIMESTAMP | INFO | $1" >> "$LOG_FILE"
}

log_error() {
    echo "$TIMESTAMP | ERROR | $1" >> "$LOG_FILE"
}

# 메일 알람 함수
send_mail_alert() {
    SUBJECT="[ALERT] Disk usage threshold exceeded on group $ANSIBLE_GROUP"
    {
        echo "Disk usage exceeded the threshold ($THRESHOLD%) on one or more hosts in group: $ANSIBLE_GROUP"
        echo
        echo "Check Time: $TIMESTAMP"
        echo
        echo "Details:"
        echo "---------------------------"
        cat "$LOG_FILE"
        echo
        echo "Raw Output:"
        echo "$output"
    } | mail -s "$SUBJECT" "$MAIL_RECIPIENT"
}

export ANSIBLE_HOST_KEY_CHECKING=False

# 파라미터 확인
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: sudo $0 <THRESHOLD%> <ANSIBLE_GROUP> [--debug]"
    exit 1
fi

THRESHOLD=$(echo "$1" | sed 's/%//g')
ANSIBLE_GROUP=$2

# Ansible 그룹 검증
if ! grep -iq "\[$ANSIBLE_GROUP\]" "/home/sysadmin/ansible/hosts"; then
    log_error "Ansible group '$ANSIBLE_GROUP' not found or parsed incorrectly."
    exit 1
fi

log_debug "Executing Ansible command for group '$ANSIBLE_GROUP'"

# Ansible 명령 실행
output=$(ansible "$ANSIBLE_GROUP" -i "/home/sysadmin/ansible/hosts" \
    --private-key="/home/sysadmin/.ssh/id_rsa" -m shell \
    -a "df -h | awk '\$5+0 > $THRESHOLD {print \$0}'" 2>&1)

if [ $? -ne 0 ]; then
    log_error "Ansible command failed. Check debug.log for details."
    echo "$output" >> "$DEBUG_LOG"
    send_mail_alert
    exit 1
fi

log_info "Ansible executed successfully."
echo "==========================================" >> "$LOG_FILE"

# 출력 파싱 및 로그 파일에 기록
echo "$output" | awk '
    /^\S+ \| SUCCESS \|/ { host=$1; next }
    /^\S+ \| CHANGED \|/ { host=$1; next }
    /^\S+ \| FAILED \|/ { host=""; next }
    /^\S+ \| UNREACHABLE \|/ { host=""; next }
    /^$/ { next }
    { if (host != "") print host " | " $0 >> "'"$LOG_FILE"'" }
'

# 디버그 로그에 전체 출력 기록
echo "$output" >> "$DEBUG_LOG"

# 임계치를 초과한 결과가 로그 파일에 기록되었는지 확인
if grep -qE '^\S+ \| ' "$LOG_FILE"; then
    log_info "Disk usage exceeded threshold on one or more hosts. Sending alert email."
    send_mail_alert
else
    log_info "No disk usage issues detected."
fi
