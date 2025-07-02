#!/bin/bash

LOG_TAG="kafka_check"
CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")

KAFKA_BROKERS=(
  ".22.201:9092"
  ".22.202:9092"
  ".22.203:9092"
  ".22.204:9092"
  ".22.205:9092"
  ".22.206:9092"
  ".22.207:9092"
  ".22.208:9092"
)

KAFKA_SCRIPT_PATH="/home/username/kafka/bin"
TOPIC="sys"
CONSUMER_GROUP="analysis-syslog"
LAG_THRESHOLD=10000

offline_partitions_total=0
partitions_without_leader_total=0
lag_exceeded_total=0

STATUS_OK=true
ERROR_MESSAGES=()

for BROKER in "${KAFKA_BROKERS[@]}"; do
  current_lag=$($KAFKA_SCRIPT_PATH/kafka-consumer-groups.sh --bootstrap-server $BROKER --describe --group $CONSUMER_GROUP 2>/dev/null | grep $TOPIC | awk '{print $6}')
  current_lag=${current_lag:-0}
  if ! [[ "$current_lag" =~ ^[0-9]+$ ]]; then
    current_lag=0
  fi

  offline_partitions=$($KAFKA_SCRIPT_PATH/kafka-topics.sh --describe --bootstrap-server $BROKER 2>/dev/null | grep "Offline" | wc -l)
  partitions_without_leader=$($KAFKA_SCRIPT_PATH/kafka-topics.sh --describe --bootstrap-server $BROKER 2>/dev/null | grep "Leader: -1" | wc -l)

  offline_partitions_total=$((offline_partitions_total + offline_partitions))
  partitions_without_leader_total=$((partitions_without_leader_total + partitions_without_leader))

  if [ "$current_lag" -gt "$LAG_THRESHOLD" ]; then
    lag_exceeded_total=$((lag_exceeded_total + 1))
  fi
done

if [ "$offline_partitions_total" -gt 0 ]; then
  msg="CRITICAL: Topic=$TOPIC, Offline_Partitions=$offline_partitions_total across brokers, Consumer_Group=$CONSUMER_GROUP"
  logger -t "$LOG_TAG" -p local0.err "$msg"
  echo "$CURRENT_TIME | $msg"
  ERROR_MESSAGES+=("$msg")
  STATUS_OK=false
fi

if [ "$partitions_without_leader_total" -gt 0 ]; then
  msg="CRITICAL: Topic=$TOPIC, Partitions_without_Leader=$partitions_without_leader_total across brokers, Consumer_Group=$CONSUMER_GROUP"
  logger -t "$LOG_TAG" -p local0.err "$msg"
  echo "$CURRENT_TIME | $msg"
  ERROR_MESSAGES+=("$msg")
  STATUS_OK=false
fi

if [ "$lag_exceeded_total" -gt 0 ]; then
  msg="CRITICAL: Topic=$TOPIC, Lag exceeded threshold on $lag_exceeded_total brokers, Threshold=$LAG_THRESHOLD, Consumer_Group=$CONSUMER_GROUP"
  logger -t "$LOG_TAG" -p local0.err "$msg"
  echo "$CURRENT_TIME | $msg"
  ERROR_MESSAGES+=("$msg")
  STATUS_OK=false
fi

if $STATUS_OK; then
  echo "$CURRENT_TIME | Status=OK, Topic=$TOPIC, Lag=$current_lag, Threshold=$LAG_THRESHOLD, Offline_Partitions=$offline_partitions_total, Partitions_without_Leader=$partitions_without_leader_total, Kafka_Brokers=${#KAFKA_BROKERS[@]}"
  exit 0
else
  {
    echo "[ALERT] Kafka 장애 감지"
    echo "실행 시간: $CURRENT_TIME"
    echo ""
    echo "장애 상태:"
    for m in "${ERROR_MESSAGES[@]}"; do
      echo "- $m"
    done
  } | mail -s "[ALERT] Kafka 장애 감지 ($TOPIC)" plura@qubitsec.com
  exit 2
fi
