# Mysql

## Replication Delay Check

### 1.1 detect_check_replication_delay.sh
````
#!/bin/bash

LOG_TAG="plura_batch"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
HOSTNAME=$(hostname)

MASTER_HOST="10.10.21.60"
SLAVE_HOSTS=("10.10.21.62" "10.10.21.63" "10.10.21.64")  # 다중 Slave 호스트 IP 목록
SSH_USER="root"  # SSH 접속에 사용할 사용자
MYSQL_USER="root"
MYSQL_PASSWORD="abcroot"

# MySQL 접속 테스트 함수
function test_mysql_connection {
    local host=$1
    local test_result=$(ssh $SSH_USER@$host "mysql -u $MYSQL_USER -p'$MYSQL_PASSWORD' -e 'SELECT 1;' 2>&1")
    if [[ "$test_result" == *"ERROR"* ]]; then
        logger -t $LOG_TAG -p local0.err "$TIMESTAMP | ERROR: MySQL connection failed on $host - $test_result"
        exit 1
    fi
}

# Master 상태 확인 함수
function check_master_status {
    local host=$1
    local master_status=$(ssh $SSH_USER@$host "mysql -u $MYSQL_USER -p'$MYSQL_PASSWORD' -e 'SHOW MASTER STATUS\G'" 2>&1)
    if [ -z "$master_status" ]; then
        logger -t $LOG_TAG -p local0.err "$TIMESTAMP | ERROR: Failed to retrieve master status from MySQL on $host."
        exit 1
    fi
    MASTER_LOG_FILE=$(echo "$master_status" | grep -w 'File:' | awk '{print $2}')
    MASTER_LOG_POS=$(echo "$master_status" | grep -w 'Position:' | awk '{print $2}')
}

# Slave 상태 확인 함수
function check_slave_status {
    local host=$1
    local slave_status=$(ssh $SSH_USER@$host "mysql -u $MYSQL_USER -p'$MYSQL_PASSWORD' -e 'SHOW SLAVE STATUS\G'" 2>&1)
    if [ -z "$slave_status" ]; then
        logger -t $LOG_TAG -p local0.err "$TIMESTAMP | ERROR: Failed to retrieve slave status from MySQL on $host."
        exit 1
    fi
    SLAVE_MASTER_LOG_FILE=$(echo "$slave_status" | grep -w 'Master_Log_File:' | awk '{print $2}')
    SLAVE_RELAY_LOG_FILE=$(echo "$slave_status" | grep -w 'Relay_Master_Log_File:' | awk '{print $2}')
    SECS_BEHIND_MASTER=$(echo "$slave_status" | grep -w 'Seconds_Behind_Master:' | awk '{print $2}')
    SLAVE_IO_RUNNING=$(echo "$slave_status" | grep -w 'Slave_IO_Running:' | awk '{print $2}')
    SLAVE_SQL_RUNNING=$(echo "$slave_status" | grep -w 'Slave_SQL_Running:' | awk '{print $2}')
}

# MySQL 접속 테스트
test_mysql_connection $MASTER_HOST

# Master 상태 확인
check_master_status $MASTER_HOST

# 다중 Slave에 대해 반복적으로 상태 확인
for SLAVE_HOST in "${SLAVE_HOSTS[@]}"; do
    # MySQL 접속 테스트
    test_mysql_connection $SLAVE_HOST

    # Slave 상태 확인
    check_slave_status $SLAVE_HOST

    # 동기화 지연 시간 NULL 처리
    if [ -z "$SECS_BEHIND_MASTER" ]; then
        SECS_BEHIND_MASTER="NULL"
    fi


    # 동기화가 되지 않았을 경우 처리
    if [ "$SLAVE_IO_RUNNING" != "Yes" ] || [ "$SLAVE_SQL_RUNNING" != "Yes" ]; then
        logger -t $LOG_TAG -p local0.err "ERROR: Slave IO or SQL process is not running on $SLAVE_HOST! Check replication status."
    fi

    # 로그 메시지 출력 형식
    logger -t $LOG_TAG -p local0.info "Slave=$SLAVE_HOST, Master Log File=$MASTER_LOG_FILE, Master Log Position=$MASTER_LOG_POS, Slave Master Log File=$SLAVE_MASTER_LOG_FILE, Relay Log File=$SLAVE_RELAY_LOG_FILE, Seconds Behind Master=$SECS_BEHIND_MASTER, Slave_IO_Running=$SLAVE_IO_RUNNING, Slave_SQL_Running=$SLAVE_SQL_RUNNING"
done
````

### 1.2 logger
````
# 로그 메시지 출력 형식
logger -t $LOG_TAG -p local0.info "Slave=$SLAVE_HOST, Master Log File=$MASTER_LOG_FILE, Master Log Position=$MASTER_LOG_POS, Slave Master Log File=$SLAVE_MASTER_LOG_FILE, Relay Log File=$SLAVE_RELAY_LOG_FILE, Seconds Behind Master=$SECS_BEHIND_MASTER, Slave_IO_Running=$SLAVE_IO_RUNNING, Slave_SQL_Running=$SLAVE_SQL_RUNNING"
````

````
Slave=$SLAVE_HOST,
Master Log File=$MASTER_LOG_FILE,
Master Log Position=$MASTER_LOG_POS,
Slave Master Log File=$SLAVE_MASTER_LOG_FILE,
Relay Log File=$SLAVE_RELAY_LOG_FILE,
Seconds Behind Master=$SECS_BEHIND_MASTER,
Slave_IO_Running=$SLAVE_IO_RUNNING,
Slave_SQL_Running=$SLAVE_SQL_RUNNING
````

### 1.3 Change Property
````
chmod a+x 220_detect_check_replication_delay.sh
chmod a+x /root/plura_batch/230_detect_check_replication_delay.sh
chmod a+x /root/plura_batch/60_detect_check_replication_delay.sh
````

### 1.4 Edit crontab
````
crontab -l
crontab -e
    
systemctl restart crond
systemctl status crond
````

### 1.5 crontab -l
````   
*/20 * * * * /root/plura_batch/220_detect_check_replication_delay.sh > /dev/null 2>&1 &
*/30 * * * * /root/plura_batch/230_detect_check_replication_delay.sh > /dev/null 2>&1 &
*/60 * * * * /root/plura_batch/60_detect_check_replication_delay.sh > /dev/null 2>&1 &
```` 

### X. Useful Links

https://www.server-world.info/en/note?os=CentOS_Stream_8&p=mysql8&f=1

