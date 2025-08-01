#!/bin/bash

# 공통 설정 불러오기
source "$(dirname "$0")/solr_config-061069.conf"

LOG_TAG="solr_check"
CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")

# 응답 확인
response=$(curl -s --max-time 5 "$SOLR_URL")
if [ $? -ne 0 ] || [ -z "$response" ]; then
  message="CRITICAL: Solr 접속 실패 ($SOLR_HOST:$SOLR_PORT)"
  logger -t $LOG_TAG -p local0.err "$message"
  echo "$CURRENT_TIME | $message"
  echo "[ALERT] Solr 접속 실패" | mail -s "[ALERT] Solr 접속 실패 ($SOLR_HOST)" joo@qubitsec.com

  # 장애 재확인 스크립트 호출
  /home/sysadmin/check/solrweb_status_retry.sh
  exit 2
fi


# 여기에 삽입


# 상태 카운트 및 목록 초기화
declare -A STATE_COUNTS
declare -A STATE_CORES
STATES=("leader" "active" "recovering" "down" "recovery_failed" "inactive")

for state in "${STATES[@]}"; do
  STATE_COUNTS[$state]=0
  STATE_CORES[$state]=""
done

# core별 상태 추출
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

# 출력 및 경고 처리
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

if $STATUS_OK; then
  echo "$CURRENT_TIME | Status=OK, Solr_Host=$SOLR_HOST, Solr_Port=$SOLR_PORT"
  exit 0
else
  echo "$CURRENT_TIME | 장애 감지됨 → retry 스크립트 호출"
  /home/sysadmin/check/solrweb_status_retry.sh
  exit 2
fi
