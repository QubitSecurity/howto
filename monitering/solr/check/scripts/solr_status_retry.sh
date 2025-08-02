#!/bin/bash

# 사용법 안내
if [ -z "$1" ]; then
  echo "Usage: $0 <config_file>"
  exit 1
fi

# 설정 파일 로드
CONFIG_FILE="$1"
source "$CONFIG_FILE"

LOG_TAG="solr_check"
CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")
DOWN_LOG="/tmp/down_${SOLR_HOST}.log"

# 장애 카운트 파일 초기화
[ ! -f "$DOWN_LOG" ] && echo 0 > "$DOWN_LOG"
down_count=$(cat "$DOWN_LOG")

# 상태 요청
response=$(curl -s --max-time 5 "$SOLR_URL")
if [ $? -ne 0 ] || [ -z "$response" ]; then
  echo "$CURRENT_TIME | Solr 접속 실패 ($SOLR_HOST:$SOLR_PORT)"
  logger -t $LOG_TAG -p local0.err "Solr 접속 실패 ($SOLR_HOST:$SOLR_PORT)"
  down_count=$((down_count + 1))

  if [ "$down_count" -le 3 ]; then
    echo "$down_count" > "$DOWN_LOG"
    echo "$CURRENT_TIME | 장애 감지 (${down_count}/3 회차)"
    sleep 60
    exec "$0" "$CONFIG_FILE"
  else
    echo "$CURRENT_TIME | 3회 연속 접속 실패 발생, 종료"
    logger -t $LOG_TAG -p local0.err "3회 연속 Solr 접속 실패 발생 ($SOLR_HOST)"
    {
      echo "[ALERT] Solr 3회 연속 접속 실패"
      echo "시간: $CURRENT_TIME"
      echo ""
      echo "- Solr 접속 실패 ($SOLR_HOST:$SOLR_PORT)"
    } | mail -s "[ALERT] Solr 3회 연속 접속 실패 ($SOLR_HOST)" joo@qubitsec.com
    exit 2
  fi
fi

# 상태 파싱
declare -A STATE_COUNTS
declare -A STATE_CORES
STATES=("leader" "active" "recovering" "down" "recovery_failed" "inactive")
ERROR_STATES=("recovering" "down" "recovery_failed" "inactive")

for state in "${STATES[@]}"; do
  STATE_COUNTS[$state]=0
  STATE_CORES[$state]=""
done

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

### TEST 여기에 삽입

# 경고 여부 판단
STATUS_OK=true
ERROR_MESSAGES=()

echo "$CURRENT_TIME | Solr 상태 요약 ($SOLR_HOST:$SOLR_PORT):"
for state in "${STATES[@]}"; do
  count=${STATE_COUNTS[$state]}
  if [ "$count" -gt 0 ]; then
    echo "- ${state^}: $count core(s) (${STATE_CORES[$state]})"

    # 장애 상태일 경우만 CRITICAL 처리
    if [[ " ${ERROR_STATES[@]} " =~ " $state " ]]; then
      msg="CRITICAL: $count core(s) in $state state: ${STATE_CORES[$state]}"
      logger -t "$LOG_TAG" -p local0.err "$msg"
      echo "$CURRENT_TIME | $msg"
      ERROR_MESSAGES+=("$msg")
      STATUS_OK=false
    fi
  fi
done

# 정상 복구 시 down.log 초기화
if $STATUS_OK; then
  echo "$CURRENT_TIME | Solr 정상 응답 → 장애 복구"
  if [ "$down_count" -ne 0 ]; then
    echo 0 > "$DOWN_LOG"
    echo "$CURRENT_TIME | 장애 회복 → down.log 초기화"
  fi
  exit 0
else
  down_count=$((down_count + 1))
  echo "$down_count" > "$DOWN_LOG"
  echo "$CURRENT_TIME | 장애 감지 (${down_count}/3 회차)"

  if [ "$down_count" -le 3 ]; then
    sleep 60
    exec "$0" "$CONFIG_FILE"
  else
    {
      echo "[ALERT] Solr 3회 연속 장애 감지"
      echo "대상: $SOLR_HOST:$SOLR_PORT"
      echo "시간: $CURRENT_TIME"
      echo ""
      echo "장애 상세:"
      for m in "${ERROR_MESSAGES[@]}"; do
        echo "- $m"
      done
    } | mail -s "[ALERT] Solr 3회 연속 장애 감지 ($SOLR_HOST)" joo@qubitsec.com

    logger -t "$LOG_TAG" -p local0.err "3회 연속 장애 발생 on $SOLR_HOST"
    exit 2
  fi
fi
