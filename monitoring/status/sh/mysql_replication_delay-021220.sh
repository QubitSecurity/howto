#!/bin/bash

LOG_TAG="mysql_check"
CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")
HOSTNAME=$(hostname)

MASTER_HOST="21.220"
SLAVE_HOSTS=("21.222" "21.223" "21.224")
SSH_USER="root"
MYSQL_USER="root"
MYSQL_PASSWORD=""

STATUS_OK=true
ERROR_MESSAGES=()
MASTER_LOG_FILE=""
MASTER_LOG_POS=""
POS_TOLERANCE=1000  # Position 허용 오차 바이트

# 절대값 계산 함수
abs() {
    echo $(( $1 >= 0 ? $1 : -$1 ))
}

# Test MySQL connection
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

# Check master status
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

# Check slave status
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

    local pos_diff=$(abs $((slave_pos - MASTER_LOG_POS)))

    msg="OK: Slave=$host, Seconds_Behind_Master=$secs_behind, IO=$io_running, SQL=$sql_running"

    # 개선된 판단 로직: 슬레이브가 마스터보다 "작고", 오차 초과할 경우만 CRITICAL
    if [ "$io_running" != "Yes" ] || [ "$sql_running" != "Yes" ] || \
       { [ "$secs_behind" != "NULL" ] && [ "$secs_behind" -ge 30 ]; } || \
       [ "$slave_file" != "$MASTER_LOG_FILE" ] || \
       { [ "$slave_pos" -lt "$MASTER_LOG_POS" ] && [ "$pos_diff" -gt "$POS_TOLERANCE" ]; }; then
        msg="CRITICAL: Slave=$host, Seconds_Behind_Master=$secs_behind, IO=$io_running, SQL=$sql_running, File=$slave_file/$MASTER_LOG_FILE, Pos=$slave_pos/$MASTER_LOG_POS (Δ=$pos_diff)"
        logger -t $LOG_TAG -p local0.err "$msg"
        echo "$CURRENT_TIME | $msg"
        ERROR_MESSAGES+=("$msg")
        return 1
    fi

    echo "$CURRENT_TIME | $msg"
    return 0
}

# Run master check
test_mysql_connection $MASTER_HOST && check_master_status $MASTER_HOST || STATUS_OK=false

# Run slave checks
for host in "${SLAVE_HOSTS[@]}"; do
    test_mysql_connection $host && check_slave_status $host || STATUS_OK=false
done

# Summary & mail
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
    } | mail -s "[ALERT] MySQL 복제 이상 ($HOSTNAME)" plura@qubitsec.com
    exit 2
fi
