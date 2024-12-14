#!/bin/bash

LOG_TAG="mysql_check"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
HOSTNAME=$(hostname)

# Check if master and slave host files are provided as parameters
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <master_host_file> <slave_host_file>"
    exit 1
fi

# Read master and slave host files
MASTER_HOST_FILE="$1"
SLAVE_HOST_FILE="$2"

if [ ! -f "$MASTER_HOST_FILE" ]; then
    echo "Error: Master host file '$MASTER_HOST_FILE' not found."
    exit 1
fi

if [ ! -f "$SLAVE_HOST_FILE" ]; then
    echo "Error: Slave host file '$SLAVE_HOST_FILE' not found."
    exit 1
fi

MASTER_HOST=$(cat "$MASTER_HOST_FILE")
SLAVE_HOSTS=($(cat "$SLAVE_HOST_FILE"))

SSH_USER="root"  # SSH 접속 사용자
MYSQL_USER="root"
MYSQL_PASSWORD="password"

# Set the log file path for normal operation
SCRIPT_DIR=$(dirname "$(realpath "$0")")
LOG_FILE="$SCRIPT_DIR/check_status_mysql.log"

# Function to test MySQL connection
function test_mysql_connection {
    local host=$1
    local test_result=$(ssh $SSH_USER@$host "mysql -u $MYSQL_USER -p'$MYSQL_PASSWORD' -e 'SELECT 1;' 2>&1")
    if [[ "$test_result" == *"ERROR"* ]]; then
        local message="Status=ERROR, Host=$host, Message=MySQL connection failed - $test_result"
        logger -t $LOG_TAG -p local0.err "$message"
        echo "$TIMESTAMP | $message" >> $LOG_FILE
        return 1
    fi
    return 0
}

# Function to check Master status
function check_master_status {
    local host=$1
    local master_status=$(ssh $SSH_USER@$host "mysql -u $MYSQL_USER -p'$MYSQL_PASSWORD' -e 'SHOW MASTER STATUS\\G'" 2>&1)
    
    if [[ -z "$master_status" || "$master_status" == *"ERROR"* ]]; then
        local message="Status=ERROR, Master=$host, Message=Failed to retrieve master status"
        logger -t $LOG_TAG -p local0.err "$message"
        echo "$TIMESTAMP | $message" >> $LOG_FILE
        return 1
    fi

    MASTER_LOG_FILE=$(echo "$master_status" | grep -w 'File:' | awk '{print $2}')
    MASTER_LOG_POS=$(echo "$master_status" | grep -w 'Position:' | awk '{print $2}')
    
    if [ -z "$MASTER_LOG_FILE" ] || [ -z "$MASTER_LOG_POS" ]; then
        local message="Status=ERROR, Master=$host, Message=Invalid master status - File: $MASTER_LOG_FILE, Position: $MASTER_LOG_POS"
        logger -t $LOG_TAG -p local0.err "$message"
        echo "$TIMESTAMP | $message" >> $LOG_FILE
        return 1
    fi

    # 정상 상태 로그 기록
    local message="Status=OK, Master=$host, Master_Log_File=$MASTER_LOG_FILE, Master_Log_Position=$MASTER_LOG_POS"
    echo "$TIMESTAMP | $message" >> $LOG_FILE
    return 0
}

# Function to check Slave status
function check_slave_status {
    local host=$1
    local slave_status=$(ssh $SSH_USER@$host "mysql -u $MYSQL_USER -p'$MYSQL_PASSWORD' -e 'SHOW SLAVE STATUS\\G'" 2>&1)
    
    if [[ -z "$slave_status" || "$slave_status" == *"ERROR"* ]]; then
        local message="Status=ERROR, Slave=$host, Message=Failed to retrieve slave status"
        logger -t $LOG_TAG -p local0.err "$message"
        echo "$TIMESTAMP | $message" >> $LOG_FILE
        return 1
    fi

    local SLAVE_MASTER_LOG_FILE=$(echo "$slave_status" | grep -w 'Master_Log_File:' | awk '{print $2}')
    local SLAVE_RELAY_LOG_FILE=$(echo "$slave_status" | grep -w 'Relay_Master_Log_File:' | awk '{print $2}')
    local SLAVE_READ_MASTER_LOG_POS=$(echo "$slave_status" | grep -w 'Read_Master_Log_Pos:' | awk '{print $2}')
    local SLAVE_RELAY_LOG_POS=$(echo "$slave_status" | grep -w 'Exec_Master_Log_Pos:' | awk '{print $2}')
    local SECS_BEHIND_MASTER=$(echo "$slave_status" | grep -w 'Seconds_Behind_Master:' | awk '{print $2}')
    local SLAVE_IO_RUNNING=$(echo "$slave_status" | grep -w 'Slave_IO_Running:' | awk '{print $2}')
    local SLAVE_SQL_RUNNING=$(echo "$slave_status" | grep -w 'Slave_SQL_Running:' | awk '{print $2}')

    # Seconds_Behind_Master가 NULL인 경우 처리
    if [ -z "$SECS_BEHIND_MASTER" ]; then
        SECS_BEHIND_MASTER="NULL"
    else
        SECS_BEHIND_MASTER=$(expr $SECS_BEHIND_MASTER + 0)  # 숫자 비교를 위해 변환
    fi

    # 상태 메시지 생성
    local status="OK"
    local message="Status=OK, Slave=$host, Master_Log_File=$MASTER_LOG_FILE, Master_Log_Position=$MASTER_LOG_POS, Slave_Master_Log_File=$SLAVE_MASTER_LOG_FILE, Slave_Read_Master_Log_Pos=$SLAVE_READ_MASTER_LOG_POS, Relay_Master_Log_File=$SLAVE_RELAY_LOG_FILE, Exec_Master_Log_Pos=$SLAVE_RELAY_LOG_POS, Seconds_Behind_Master=$SECS_BEHIND_MASTER, Slave_IO_Running=$SLAVE_IO_RUNNING, Slave_SQL_Running=$SLAVE_SQL_RUNNING"

    # 복제 프로세스 상태 확인
    if [ "$SLAVE_IO_RUNNING" != "Yes" ] || [ "$SLAVE_SQL_RUNNING" != "Yes" ] || [ "$SECS_BEHIND_MASTER" -ge 30 ]; then
        status="ERROR"
    fi

    # 로그 파일 및 포지션 불일치 확인
    if [ "$MASTER_LOG_FILE" != "$SLAVE_MASTER_LOG_FILE" ] || [ "$MASTER_LOG_POS" != "$SLAVE_READ_MASTER_LOG_POS" ]; then
        status="ERROR"
    fi

    # 상태에 따라 로그 기록
    if [ "$status" == "ERROR" ]; then
        logger -t $LOG_TAG -p local0.err "$message"
    fi
    echo "$TIMESTAMP | $message" >> $LOG_FILE

    # 상태 반환
    if [ "$status" == "ERROR" ]; then
        return 1
    else
        return 0
    fi
}

# Main execution
overall_status=0

# Test MySQL connection to Master and check its status
test_mysql_connection $MASTER_HOST
if [ $? -ne 0 ]; then
    overall_status=1
else
    check_master_status $MASTER_HOST
    if [ $? -ne 0 ]; then
        overall_status=1
    fi
fi

# Loop through each Slave and check its status
for SLAVE_HOST in "${SLAVE_HOSTS[@]}"; do
    test_mysql_connection $SLAVE_HOST
    if [ $? -ne 0 ]; then
        overall_status=1
        continue
    fi

    check_slave_status $SLAVE_HOST
    if [ $? -ne 0 ]; then
        overall_status=1
    fi
done

exit $overall_status
