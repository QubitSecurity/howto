#!/bin/bash

LOG_TAG="redis_check"
CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")
REDIS_PORT=6381

REDIS_MASTERS=(.21.140 .21.141 .21.142 .21.143 .21.144)
REDIS_SLAVES=(.21.150 .21.151 .21.152 .21.153 .21.154)

STATUS_OK=true
ERROR_MESSAGES=()

check_redis_node() {
    local node=$1
    local expected_role=$2

    redis_info=$(redis-cli -h "$node" -p "$REDIS_PORT" CLUSTER NODES 2>/dev/null | grep "$node:$REDIS_PORT")
    if [ -z "$redis_info" ]; then
        msg="CRITICAL: Node $node:$REDIS_PORT is unreachable or unresponsive"
        logger -t "$LOG_TAG" -p local0.err "$msg"
        echo "$CURRENT_TIME | $msg"
        ERROR_MESSAGES+=("$msg")
        return 1
    fi

    role_type=$(echo "$redis_info" | awk '{print $3}' | cut -d',' -f1)
    if [[ "$role_type" == "myself" ]]; then
        role_type=$(echo "$redis_info" | awk '{print $3}' | cut -d',' -f2)
    fi

    if [ "$expected_role" != "$role_type" ]; then
        msg="CRITICAL: Node $node:$REDIS_PORT is expected to be $expected_role but found $role_type"
        logger -t "$LOG_TAG" -p local0.err "$msg"
        echo "$CURRENT_TIME | $msg"
        ERROR_MESSAGES+=("$msg")
        return 1
    fi

    return 0
}

for node in "${REDIS_MASTERS[@]}"; do
    check_redis_node "$node" "master" || STATUS_OK=false
done

for node in "${REDIS_SLAVES[@]}"; do
    check_redis_node "$node" "slave" || STATUS_OK=false
done

if $STATUS_OK; then
    echo "$CURRENT_TIME | Status=OK, Redis cluster is healthy on port $REDIS_PORT"
    exit 0
else
    {
        echo "[ALERT] Redis 장애 감지"
        echo "실행 시간: $CURRENT_TIME"
        echo ""
        echo "장애 상태:"
        for m in "${ERROR_MESSAGES[@]}"; do
            echo "- $m"
        done
    } | mail -s "[ALERT] Redis 장애 감지" plura@qubitsec.com
    exit 2
fi
