#!/bin/bash

# 공통 설정 불러오기
source "$(dirname "$0")/solr_config-061069.conf"

# 로그 태그 및 현재 시간
LOG_TAG="solr_check"
CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")

# 장애 카운트 기록 파일
DOWN_LOG="./down_${SOLR_HOST}.log"

# 상태 이름 정의
declare -A STATE_COUNTS
declare -A STATE_CORES
STATES=("leader" "active" "recovering" "down" "recovery_failed" "inactive")

# 장애 카운트 파일 없으면 생성
if [ ! -f "$DOWN_LOG" ]; then
  echo 0 > "$DOWN_LOG"
fi

# 현재 장애 카운트 읽기
down_count=$(cat "$DOWN_LOG")

# Solr 상태 요청
response=$(curl -s --max-time 5 "$SOLR_URL")
if [ $? -ne 0 ] || [ -z "$response" ]; then
  echo "$CURRENT_TIME | Solr 접속 실패 ($SOLR_HOST:$SOLR_PORT)"
  logger -t $LOG_TAG -p local0.err "Solr 접속 실패 ($SOLR_HOST:$SOLR_PORT)"
  down_count=$((down_count + 1))

  if [ "$down_count" -le 3 ]; then
    echo "$down_count" > "$DOWN_LOG"
    echo "$CURRENT_TIME | 장애 감지 (${down_count}/3 회차)"
    sleep 60
    exec "$0"
  else
    echo "$CURRENT_TIME | 3회 연속 장애, 종료"
    logger -t $LOG_TAG -p local0.err "3회 연속 장애 발생"
    echo "[ALERT] Solr 3회 연속 장애 발생 ($SOLR_HOST)" | mail -s "[ALERT] Solr 장애 감지 ($SOLR_HOST)" joo@qubitsec.com
    exit 2
  fi
fi

# 정상 응답일 경우 상태 파싱 시작
for state in "${STATES[@]}"; do
  STATE_COUNTS[$state]=0
  STATE_CORES[$state]=""
done

# core 정보 파싱
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

# 장애 여부 판단
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

# 정상 상태일 경우 장애 카운트 초기화
if $STATUS_OK; then
  echo "$CURRENT_TIME | Status=OK, 장애 없음"
  if [ "$down_count" -ne 0 ]; then
    echo 0 > "$DOWN_LOG"
    echo "$CURRENT_TIME | 장애 복구됨 → down.log 초기화"
  fi
  exit 0
else
  # 장애 감지 시 재시도 로직
  down_count=$((down_count + 1))
  if [ "$down_count" -le 3 ]; then
    echo "$down_count" > "$DOWN_LOG"
    echo "$CURRENT_TIME | 장애 감지 (${down_count}/3 회차)"
    sleep 60
    exec "$0"
  else
    {
      echo "[ALERT] Solr 3회 연속 장애 감지"
      echo "실행 시간: $CURRENT_TIME"
      for m in "${ERROR_MESSAGES[@]}"; do
        echo "- $m"
      done
    } | mail -s "[ALERT] Solr 장애 감지 ($SOLR_HOST)" joo@qubitsec.com
    echo "$CURRENT_TIME | 3회 연속 장애 발생, 종료"
    logger -t "$LOG_TAG" -p local0.err "3회 연속 장애 발생"
    exit 2
  fi
fi
