#!/bin/bash

# 공통 설정 파일 경로 지정 및 로드
CONFIG_FILE="$(dirname "$0")/solr_config-041069.conf"
source "$CONFIG_FILE"

LOG_TAG="solr_check"
CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")

# Solr 응답 확인
response=$(curl -s --max-time 5 "$SOLR_URL")
if [ $? -ne 0 ] || [ -z "$response" ]; then
  message="CRITICAL: Solr 접속 실패 ($SOLR_HOST:$SOLR_PORT)"
  logger -t "$LOG_TAG" -p local0.err "$message"
  echo "$CURRENT_TIME | $message"
  echo "[ALERT] Solr 접속 실패" | mail -s "[ALERT] Solr 접속 실패 ($SOLR_HOST)" joo@qubitsec.com

  # 장애 재확인 스크립트 호출 (config 경로 인자로 전달)
  /home/sysadmin/check/solr_status_retry.sh "$CONFIG_FILE"
  exit 2
fi

# 상태 카운트 초기화
declare -A STATE_COUNTS
declare -A STATE_CORES
STATES=("leader" "active" "recovering" "down" "recovery_failed" "inactive")

for state in "${STATES[@]}"; do
  STATE_COUNTS[$state]=0
  STATE_CORES[$state]=""
done

# core 상태 파싱
cores=$(echo "$response" | jq -r '.cluster.collections[]?.shards[]?.replicas[]? | @base64')

for core in $cores; do
  _jq() {
    echo "$core" | base64 --decode | jq -r "$1"
  }

  node=$(_jq '.node_name')
  core_name=$(_jq '.core')
  state=$(_jq '.state' | tr '[:upper:]' '[:lower:]')
  leader=$(_jq '.leader')

  if [[ "$leader" == "true" ]]; then
    STATE_COUNTS["leader"]=$((STATE_COUNTS["leader"] + 1))
    STATE_CORES["leader"]+="$core_name($node) "
  fi

  if [[ " ${STATES[@]} " =~ " $state " ]]; then
    STATE_COUNTS["$state"]=$((STATE_COUNTS["$state"] + 1))
    STATE_CORES["$state"]+="$core_name($node) "
  fi
done

# 상태 판단 및 출력
STATUS_OK=true
ERROR_MESSAGES=()

echo "$CURRENT_TIME | Solr 상태 요약 ($SOLR_HOST:$SOLR_PORT):"
for state in "${STATES[@]}"; do
  count=${STATE_COUNTS[$state]}
  if [ "$count" -gt 0 ]; then
    echo "- ${state^}: $count core(s) (${STATE_CORES[$state]})"
    if [[ "$state" != "active" && "$state" != "leader" ]]; then
      msg="CRITICAL: $count core(s) in $state state: ${STATE_CORES[$state]}"
      logger -t "$LOG_TAG" -p local0.err "$msg"
      echo "$CURRENT_TIME | $msg"
      ERROR_MESSAGES+=("$msg")
      STATUS_OK=false
    fi
  fi
done

# 정상 or 장애 판단 후 조치
if $STATUS_OK; then
  echo "$CURRENT_TIME | Status=OK"
  exit 0
else
  echo "$CURRENT_TIME | 장애 감지됨 → retry 스크립트 호출"
  /home/sysadmin/check/solr_status_retry.sh "$CONFIG_FILE"
  exit 2
fi
