#!/bin/bash

LOG_TAG="solr_log_check"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

SCRIPT_DIR=$(dirname "$(realpath "$0")")

# 로그 파일 설정
LOG_FILE="$SCRIPT_DIR/check_solr_gc_usage.log"
DEBUG_LOG="$SCRIPT_DIR/debug.log"
SUMMARY_FILE="$SCRIPT_DIR/summary.log"

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

export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_TIMEOUT=60

# 파라미터 확인
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: sudo $0 <SEARCH_KEYWORD> <IP_ADDRESS|ANSIBLE_GROUP>"
    exit 1
fi

SEARCH_KEYWORD=$1
TARGET=$2
MAX_RETRIES=3
RETRY_DELAY=5

# Ansible 명령 실행 함수
execute_ansible_command() {
    log_debug "Executing command: ansible all -i '$TARGET,' --private-key='~/.ssh/id_rsa' -m shell -a 'grep -E \"$SEARCH_KEYWORD\" /home/sysadmin/solr/server/logs/solr_gc.log || true'"
    ansible all -i "$TARGET," --private-key="~/.ssh/id_rsa" -m shell \
        -a "grep -E '$SEARCH_KEYWORD' /home/sysadmin/solr/server/logs/solr_gc.log || true" 2>&1
}

# 대상 서버에서 로그 파일 존재 여부 확인 함수
check_log_file_existence() {
    ansible all -i "$TARGET," --private-key="~/.ssh/id_rsa" -m shell \
        -a "[ -f /home/sysadmin/solr/server/logs/solr_gc.log ] || echo 'Log file not found'" 2>&1
}

# 로그 파일 유효성 검사
log_file_check=$(check_log_file_existence)
if echo "$log_file_check" | grep -q "Log file not found"; then
    log_error "Log file not found on target server. Ensure the path is correct: /home/sysadmin/solr/server/logs/solr_gc.log"
    echo "Error: Log file not found on target server. Check debug.log for details."
    exit 1
fi

# 재시도 로직
for ((i=1; i<=MAX_RETRIES; i++)); do
    output=$(execute_ansible_command)
    if [ $? -eq 0 ]; then
        log_info "Ansible executed successfully."
        break
    else
        log_error "Attempt $i failed. Retrying in $RETRY_DELAY seconds..."
        echo "$output" >> "$DEBUG_LOG"
        if [ $i -lt $MAX_RETRIES ]; then
            sleep $RETRY_DELAY
        else
            log_error "Ansible command failed after $MAX_RETRIES attempts."
            exit 1
        fi
    fi
done

# 출력 파싱 및 로그 파일에 기록
problematic_servers=0
echo "$output" | awk -v logfile="$LOG_FILE" -v summaryfile="$SUMMARY_FILE" '
    BEGIN {
        print "Summary of Issues:" > summaryfile
    }
    /^\S+ \| SUCCESS \|/ { host=$1; next }
    /^\S+ \| CHANGED \|/ { host=$1; next }
    /^\S+ \| FAILED \|/ { host=""; next }
    /^\S+ \| UNREACHABLE \|/ { host=""; next }
    /^$/ { next }
    {
        if (host != "") {
            print host " | " $0 >> logfile
            issues[host]++
        }
    }
    END {
        for (server in issues) {
            print server " | Issues found: " issues[server] >> summaryfile
            problematic_servers++
        }
        print "Total problematic servers: " problematic_servers >> summaryfile
    }
'

# 디버그 로그에 전체 출력 기록
echo "$output" >> "$DEBUG_LOG"

# 결과 요약 표시
cat "$SUMMARY_FILE"
