#!/bin/bash

LOG_TAG="mysql_check"
CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")
HOSTNAME=$(hostname)

MASTER_HOST="21.230"
SLAVE_HOSTS=("21.232" "21.233" "21.234")
SSH_USER="root"
MYSQL_USER="root"
MYSQL_PASSWORD=""

MAX_ALLOWED_DELAY=200           # Seconds_Behind_Master 허용 범위
MAX_ALLOWED_LOG_POSITION_DIFF=20000000  # 20MB 포지션 차이 허용

STATUS_OK=true
ERROR_MESSAGES=()
MASTER_LOG_FILE=""
MASTER_LOG_POS=""

test_mysql_connection() {
    local host=$1
    ssh $SSH_USER@$host "mysql -u $MYSQL_USER -p'$MYSQL_PASSWORD' -e 'SELECT 1;'" &>/dev/null
    if [ $? -ne 0 ]; then
        msg="ERROR: MySQL connection failed on $host"
        logger -t $LOG_TAG -p local0.err "$msg"
        echo "$CURRENT_TIME | $msg"
        ERROR_MESSAGES+=("$msg")
        return 1
    fi
    return 0
}

check_master_status() {
    local host=$1
    local result=$(ssh $SSH_USER@$host "mysql -u $MYSQL_USER -p'$MYSQL_PASSWORD' -e 'SHOW MASTER STATUS\G'" 2>/dev/null)

    if [[ -z "$result" ]]; then
        msg="ERROR: Failed to retrieve master status from $host"
        logger -t $LOG_TAG -p local0.err "$msg"
        echo "$CURRENT_TIME | $msg"
        ERROR_MESSAGES+=("$msg")
        return 1
    fi

    MASTER_LOG_FILE=$(echo "$result" | grep -w 'File:' | awk '{print $2}')
    MASTER_LOG_POS=$(echo "$result" | grep -w 'Position:' | awk '{print $2}')

    if [ -z "$MASTER_LOG_FILE" ] || [ -z "$MASTER_LOG_POS" ]; then
        msg="ERROR: Invalid master status - File=$MASTER_LOG_FILE, Position=$MASTER_LOG_POS"
        logger -t $LOG_TAG -p local0.err "$msg"
        echo "$CURRENT_TIME | $msg"
        ERROR_MESSAGES+=("$msg")
        return 1
    fi

    echo "$CURRENT_TIME | OK: Master=$host, File=$MASTER_LOG_FILE, Position=$MASTER_LOG_POS"
    return 0
}

check_slave_status() {
    local host=$1
    local result=$(ssh $SSH_USER@$host "mysql -u $MYSQL_USER -p'$MYSQL_PASSWORD' -e 'SHOW SLAVE STATUS\G'" 2>/dev/null)

    if [[ -z "$result" ]]; then
        msg="ERROR: Failed to retrieve slave status from $host"
        logger -t $LOG_TAG -p local0.err "$msg"
        echo "$CURRENT_TIME | $msg"
        ERROR_MESSAGES+=("$msg")
        return 1
    fi

    local slave_file=$(echo "$result" | grep -w 'Master_Log_File:' | awk '{print $2}')
    local slave_pos=$(echo "$result" | grep -w 'Read_Master_Log_Pos:' | awk '{print $2}')
    local secs_behind=$(echo "$result" | grep -w 'Seconds_Behind_Master:' | awk '{print $2}')
    local io_running=$(echo "$result" | grep -w 'Slave_IO_Running:' | awk '{print $2}')
    local sql_running=$(echo "$result" | grep -w 'Slave_SQL_Running:' | awk '{print $2}')

    secs_behind=${secs_behind:-NULL}
    [ "$secs_behind" != "NULL" ] && secs_behind=$(expr $secs_behind + 0)

    msg="OK: Slave=$host, Seconds_Behind_Master=$secs_behind, IO=$io_running, SQL=$sql_running"
    status="OK"

    # 지연 시간 초과
    if [ "$secs_behind" != "NULL" ] && [ "$secs_behind" -ge "$MAX_ALLOWED_DELAY" ]; then
        status="ERROR"
    fi

    # 복제 프로세스 비정상
    if [ "$io_running" != "Yes" ] || [ "$sql_running" != "Yes" ]; then
        status="ERROR"
    fi

    # 로그 포지션 차이 비교
    if [[ "$MASTER_LOG_POS" =~ ^[0-9]+$ && "$slave_pos" =~ ^[0-9]+$ ]]; then
        pos_diff=$((MASTER_LOG_POS - slave_pos))
        [ $pos_diff -lt 0 ] && pos_diff=$(( -1 * pos_diff ))
        if [ "$pos_diff" -ge "$MAX_ALLOWED_LOG_POSITION_DIFF" ]; then
            status="ERROR"
            msg="$msg, Log_Position_Diff=${pos_diff}B"
        fi
    fi

    if [ "$status" == "ERROR" ]; then
        msg="CRITICAL: $msg, File=$slave_file/$MASTER_LOG_FILE, Pos=$slave_pos/$MASTER_LOG_POS"
        logger -t $LOG_TAG -p local0.err "$msg"
        echo "$CURRENT_TIME | $msg"
        ERROR_MESSAGES+=("$msg")
        return 1
    else
        echo "$CURRENT_TIME | $msg"
        return 0
    fi
}

# 점검 시작
test_mysql_connection $MASTER_HOST && check_master_status $MASTER_HOST || STATUS_OK=false

for host in "${SLAVE_HOSTS[@]}"; do
    test_mysql_connection $host && check_slave_status $host || STATUS_OK=false
done

# 결과 판단 및 메일
if $STATUS_OK; then
    exit 0
else
    {
        echo "[ALERT] MySQL 복제 상태 이상 감지"
        echo "실행 시간: $CURRENT_TIME"
        echo ""
        echo "장애 내용:"
        for m in "${ERROR_MESSAGES[@]}"; do
            echo "- $m"
        done
    } | mail -s "[ALERT] MySQL 복제 이상 ($HOSTNAME)" joo@qubitsec.com
    exit 2
fi
