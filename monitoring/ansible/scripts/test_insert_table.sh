#!/bin/bash

LOG_TAG="mysql_insert_check"
CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")
HOSTNAME=$(hostname)

DB_HOST="21.60"
SSH_USER="root"
MYSQL_USER="root"
MYSQL_PASSWORD=""
DB_NAME="monitoring"
TEST_TABLE="test_insert_table"
MAIL_RECIPIENT="plura@qubitsec.com"

STATUS_OK=true
ERROR_MESSAGES=()

# UUID 생성
UUID=$(uuidgen)

# SQL 명령어 정의
CREATE_TABLE_SQL="CREATE TABLE IF NOT EXISTS $TEST_TABLE (id INT AUTO_INCREMENT PRIMARY KEY, test_key VARCHAR(64), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
INSERT_SQL="INSERT INTO $TEST_TABLE (test_key) VALUES ('$UUID');"
CHECK_SQL="SELECT COUNT(*) FROM $TEST_TABLE WHERE test_key = '$UUID';"

# MySQL 명령 래퍼
exec_mysql() {
    local query="$1"
    ssh $SSH_USER@$DB_HOST "mysql -u $MYSQL_USER -p'$MYSQL_PASSWORD' -D $DB_NAME -e \"$query\""
    return $?
}

# 1. 연결 확인
exec_mysql "SELECT 1;" &>/dev/null
if [ $? -ne 0 ]; then
    msg="ERROR: MySQL 연결 실패 ($DB_HOST)"
    logger -t $LOG_TAG -p local0.err "$msg"
    echo "$CURRENT_TIME | $msg"
    ERROR_MESSAGES+=("$msg")
    STATUS_OK=false
fi

# 2. 테이블 생성
if $STATUS_OK; then
    exec_mysql "$CREATE_TABLE_SQL" &>/dev/null
    if [ $? -ne 0 ]; then
        msg="ERROR: 테이블 생성 실패"
        logger -t $LOG_TAG -p local0.err "$msg"
        echo "$CURRENT_TIME | $msg"
        ERROR_MESSAGES+=("$msg")
        STATUS_OK=false
    fi
fi

# 3. INSERT 수행
if $STATUS_OK; then
    exec_mysql "$INSERT_SQL" &>/dev/null
    if [ $? -ne 0 ]; then
        msg="ERROR: INSERT 실패 (UUID=$UUID)"
        logger -t $LOG_TAG -p local0.err "$msg"
        echo "$CURRENT_TIME | $msg"
        ERROR_MESSAGES+=("$msg")
        STATUS_OK=false
    fi
fi

# 4. SELECT 확인
if $STATUS_OK; then
    result=$(exec_mysql "$CHECK_SQL" 2>/dev/null | tail -n 1)
    if [ "$result" != "1" ]; then
        msg="ERROR: INSERT 데이터 SELECT 실패 (UUID=$UUID)"
        logger -t $LOG_TAG -p local0.err "$msg"
        echo "$CURRENT_TIME | $msg"
        ERROR_MESSAGES+=("$msg")
        STATUS_OK=false
    fi
fi

# 5. 결과에 따라 메일 알림
if $STATUS_OK; then
    echo "$CURRENT_TIME | OK: MySQL INSERT 테스트 성공 (UUID=$UUID)"
    exit 0
else
    {
        echo "[ALERT] MySQL INSERT 테스트 실패"
        echo "서버: $HOSTNAME"
        echo "시간: $CURRENT_TIME"
        echo ""
        echo "오류 내용:"
        for m in "${ERROR_MESSAGES[@]}"; do
            echo "- $m"
        done
    } | mail -s "[ALERT] MySQL INSERT 실패 감지 ($HOSTNAME)" "$MAIL_RECIPIENT"
    exit 2
fi
