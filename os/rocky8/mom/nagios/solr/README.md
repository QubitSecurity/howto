## 1. Solr


### 1.1 Run and Stop

```
nagios -v /etc/nagios/nagios.cfg
```
```
systemctl restart nagios
```

### 2.0 Config

```
vi /etc/nagios/objects/services.cfg

define service{
        name                            solr-status-service         ; The 'name' of this service template
        active_checks_enabled           1                       ; Active service checks are enabled
        passive_checks_enabled          1                       ; Passive service checks are enabled/accepted
        parallelize_check               1                       ; Active service checks should be parallelized (disabling this can lead to major performance problems)
        obsess_over_service             1                       ; We should obsess over this service (if necessary)
        check_freshness                 0                       ; Default is to NOT check service 'freshness'
        notifications_enabled           1                       ; Service notifications are enabled
        event_handler_enabled           1                       ; Service event handler is enabled
        flap_detection_enabled          1                       ; Flap detection is enabled
        process_perf_data               1                       ; Process performance data
        retain_status_information       1                       ; Retain status information across program restarts
        retain_nonstatus_information    1                       ; Retain non-status information across program restarts
        is_volatile                     0                       ; The service is not volatile
        check_period                    24x7                    ; The service can be checked at any time of the day
        max_check_attempts              3                       ; Re-check the service up to 3 times in order to determine its final (hard) state
        check_interval                  10                      ; Check the service every 10 minutes under normal conditions
        retry_interval                  2                       ; Re-check the service every two minutes until a hard state can be determined
        contact_groups                  admins                  ; Notifications get sent out to everyone in the 'admins' group
        notification_options            w,u,c,r                 ; Send notifications about warning, unknown, critical, and recovery events
        notification_interval           60                      ; Re-notify about service problems every hour
        notification_period             24x7                    ; Notifications can be sent out at any time
        register                        0                       ; DONT REGISTER THIS DEFINITION - ITS NOT A REAL SERVICE, JUST A TEMPLATE!
        }
```

<hr/>

```
vi /etc/nagios/objects/hostgroups.cfg

define hostgroup {
        hostgroup_name          solr-status
        alias                   solr
}
```

<hr/>

```
vi /etc/nagios/objects/commands.cfg

################################################################################
#
# Solr HOST CHECK COMMANDS
#
################################################################################

define command{
    command_name check_solr_status
    command_line $USER1$/check_solr_status.sh $HOSTADDRESS$ $ARG1$ $ARG2$
#    command_line    /usr/lib64/nagios/plugins/check_solr_status.sh $HOSTADDRESS$ $ARG1$ $ARG2$
}
```
<hr/>

```
vi /etc/nagios/servers/solr-syslog-status.cfg

define host{
    use                     linux-server
    host_name               solr-status
    alias                   solr-status
    address                 10.10.10.69
    hostgroups              solr-status
}

define service {
        use                     solr-status-service
        host_name               solr-status
        service_description     Solr status
        check_command           check_solr_status!8983!syslog
}
```

<hr/>

```
vi /usr/lib64/nagios/plugins/check_solr_status.sh

#!/bin/bash

# 로그 파일 경로 설정
LOG_FILE="/var/log/nagios/solr_check_status.log"

# 현재 날짜와 시간
NOW=$(date '+%Y-%m-%d %H:%M:%S')

# 인자로부터 Solr 서버 주소, 포트, 코어 이름 설정
SOLR_HOST="$1"
SOLR_PORT="$2"
SOLR_CORE="$3"

# Solr CLUSTERSTATUS API URL 구성
SOLR_URL="http://$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=CLUSTERSTATUS"

# 로그 시작 메시지 및 SOLR_URL 로깅
#echo "[$NOW] Checking Solr status for core: $SOLR_CORE on $SOLR_HOST:$SOLR_PORT using URL $SOLR_URL" >> $LOG_FILE

# curl을 사용하여 Solr의 상태 정보 가져오기
response=$(curl -s $SOLR_URL)

# 'recovering' 상태인 코어 찾기
recovering_count=$(echo $response | grep -o '"state":"recovering"' | wc -l)

# 'down' 상태인 코어 찾기
down_count=$(echo $response | grep -o '"state":"down"' | wc -l)

# 상태에 따른 처리 및 로그 기록
if [ "$recovering_count" -gt 0 ]; then
#    echo "CRITICAL: [$NOW] [$SOLR_CORE] $recovering_count core(s) are in recovering state on $SOLR_HOST:$SOLR_PORT" >> $LOG_FILE
    echo "CRITICAL: [$SOLR_CORE] $recovering_count core(s) are in recovering state on $SOLR_HOST:$SOLR_PORT"
    exit 2 # CRITICAL
elif [ "$down_count" -gt 0 ]; then
#    echo "CRITICAL: [$NOW] [$SOLR_CORE] $down_count core(s) are in down state on $SOLR_HOST:$SOLR_PORT" >> $LOG_FILE
    echo "CRITICAL: [$SOLR_CORE] $down_count core(s) are in down state on $SOLR_HOST:$SOLR_PORT"
    exit 2 # CRITICAL
else
#    echo "OK: [$NOW] All cores are in active state on $SOLR_HOST:$SOLR_PORT" >> $LOG_FILE
    echo "OK: All cores are in active state on $SOLR_HOST:$SOLR_PORT"
    exit 0 # OK
fi
```

```
chmod a+x /usr/lib64/nagios/plugins/check_solr_status.sh
```
