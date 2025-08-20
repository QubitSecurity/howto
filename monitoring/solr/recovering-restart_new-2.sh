#!/bin/bash

set -euo pipefail
trap 'echo "[$(date "+%F %T")] ❌ 오류 발생 (line $LINENO)" | tee -a "$LOG_FILE"' ERR

# 경로 설정
SOLR_BIN="/home/sysadmin/solr/bin/solr"
SOLR_DATA_DIR="/home/sysadmin/solr-data"
LOG_DIR="/home/sysadmin"
LOG_FILE="$LOG_DIR/solr_restart.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

echo "[$DATE] ▶️ Solr 재시작 작업 시작 [$HOSTNAME]" | tee -a "$LOG_FILE"

##############################
# A. 사전 용량/아이노드 점검
##############################
REQ_GB=10
avail_gb=$(df -BG / | awk 'NR==2{gsub("G","",$4); print $4}')
inode_use=$(df -i / | awk 'NR==2{print $5}' | tr -d '%')

if [ "$avail_gb" -lt "$REQ_GB" ]; then
  echo "[$DATE] ⛔ 여유공간 ${avail_gb}GB < ${REQ_GB}GB : 중단" | tee -a "$LOG_FILE"
  exit 1
fi
if [ "$inode_use" -gt 95 ]; then
  echo "[$DATE] ⛔ 아이노드 사용률 ${inode_use}% > 95% : 중단" | tee -a "$LOG_FILE"
  exit 1
fi

##############################
# 1. Solr Core 목록 감지
##############################
CORE_LIST=$(
  curl -s --max-time 5 "http://localhost:8983/solr/admin/cores?action=STATUS&wt=json" \
    | grep -o '"name":"[^"]*"' | cut -d':' -f2 | tr -d '"' | sort || true
)

if [ -z "$CORE_LIST" ]; then
  CORE_LIST=$(find "$SOLR_DATA_DIR" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; || true)
  echo "[$DATE] 🔁 Solr API 실패 → 파일 시스템에서 Core 목록 감지: $CORE_LIST" | tee -a "$LOG_FILE"
else
  echo "[$DATE] ✅ Solr API를 통해 Core 목록 감지: $CORE_LIST" | tee -a "$LOG_FILE"
fi

if [ -z "$CORE_LIST" ]; then
  echo "[$DATE] ❌ Core 목록을 감지하지 못했습니다. 스크립트 종료." | tee -a "$LOG_FILE"
  exit 1
fi

##############################
# 2. Solr 종료 시도
##############################
SOLR_PID=$(ps -ef | grep '[j]ava.*solr' | awk '{print $2}' || true)
if [ -z "${SOLR_PID:-}" ]; then
  echo "[$DATE] ℹ️ 현재 Solr 프로세스가 없습니다." | tee -a "$LOG_FILE"
else
  echo "[$DATE] 🔻 Solr stop 시도 중..." | tee -a "$LOG_FILE"
  $SOLR_BIN stop || true
  sleep 10
  SOLR_PID=$(ps -ef | grep '[j]ava.*solr' | awk '{print $2}' || true)
  if [ -n "${SOLR_PID:-}" ]; then
    echo "[$DATE] ⚠️ stop 실패. 강제 종료: PID=$SOLR_PID" | tee -a "$LOG_FILE"
    kill -9 "$SOLR_PID" || true
    sleep 5
  else
    echo "[$DATE] ✅ 정상적으로 종료됨." | tee -a "$LOG_FILE"
  fi
fi

##############################
# B. snapshot/replication & stale index.* 정리
##############################
echo "[$DATE] 🧹 snapshot/replication & stale index.* 정리..." | tee -a "$LOG_FILE"

find "$SOLR_DATA_DIR" -type d -name "snapshot*" -prune -print -exec rm -rf {} + | tee -a "$LOG_FILE" || true
find "$SOLR_DATA_DIR" -type d -name "replication" -prune -print -exec rm -rf {} + | tee -a "$LOG_FILE" || true

while IFS= read -r -d '' core; do
  data_dir="$core/data"
  [ -d "$data_dir" ] || continue
  cd "$data_dir" || continue

  # 현재 index 실경로
  cur=$(readlink -f index 2>/dev/null || realpath index 2>/dev/null || echo "$data_dir/index")
  for d in index.*; do
    [ -e "$d" ] || continue
    target=$(readlink -f "$d" 2>/dev/null || realpath "$d" 2>/dev/null || echo "$data_dir/$d")
    if [ -n "$cur" ] && [ "$target" != "$cur" ]; then
      echo "삭제: $data_dir/$d" | tee -a "$LOG_FILE"
      rm -rf --one-file-system "$d" || true
    fi
  done
done < <(find "$SOLR_DATA_DIR" -mindepth 1 -maxdepth 1 -type d -print0)

##############################
# 3. recovery, tlog, write.lock 정리
##############################
echo "[$DATE] 🧹 recovery, tlog, write.lock 정리 시작..." | tee -a "$LOG_FILE"

for CORE in $CORE_LIST; do
  echo "[$DATE] 🔍 Core: $CORE" | tee -a "$LOG_FILE"

  for DIRTYPE in recovery tlog; do
    TARGET_DIR="$SOLR_DATA_DIR/$CORE/data/$DIRTYPE"
    if [ -d "$TARGET_DIR" ]; then
      echo "삭제: $TARGET_DIR" | tee -a "$LOG_FILE"
      rm -rf "$TARGET_DIR"/* || true
    fi
  done

  LOCK_FILE="$SOLR_DATA_DIR/$CORE/data/index/write.lock"
  if [ -f "$LOCK_FILE" ]; then
    SOLR_PID=$(ps -ef | grep '[j]ava.*solr' | awk '{print $2}' || true)
    if [ -z "${SOLR_PID:-}" ]; then
      echo "[$DATE] 🔓 write.lock 제거: $LOCK_FILE" | tee -a "$LOG_FILE"
      rm -f "$LOCK_FILE" || true
    else
      echo "[$DATE] ⛔ write.lock 존재하지만 Solr 실행 중 → 삭제 생략" | tee -a "$LOG_FILE"
    fi
  fi
done

##############################
# 4. Solr 재시작
##############################
echo "[$DATE] 🔼 Solr start -cloud 수행 중..." | tee -a "$LOG_FILE"
$SOLR_BIN start -cloud || true
sleep 10

##############################
# C. 리커버리 완료 대기 (개선: ping OK 연속 시 탈출)
##############################
echo "[$(date "+%F %T")] ⏳ 리커버리 완료 대기..." | tee -a "$LOG_FILE"

MAX_WAIT_SEC=$((20*60))
INTERVAL=10
elapsed=0
consecutive_ping_ok=0
PING_OK_TARGET=3   # 연속 3회 ping OK면 운영 가능으로 간주

while :; do
  # 1) 코어 ping 먼저 확인
  all_ok=1
  for CORE in $CORE_LIST; do
    code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8983/solr/$CORE/admin/ping" || echo 000)
    if [ "$code" != "200" ]; then
      all_ok=0
      break
    fi
  done

  if [ "$all_ok" -eq 1 ]; then
    consecutive_ping_ok=$((consecutive_ping_ok+1))
  else
    consecutive_ping_ok=0
  fi

  # 2) CLUSTERSTATUS에서 비-Active 개수 계산
  json=$(curl -s --max-time 5 "http://localhost:8983/solr/admin/collections?action=CLUSTERSTATUS&wt=json" || true)
  not_active_lines=$(echo "$json" | grep -oE '"state":"(recovering|down|recovery_failed|inactive)"' || true)
  count_not_active=$(printf "%s\n" "$not_active_lines" | wc -l | tr -d ' ')

  if [ "$count_not_active" -eq 0 ]; then
    echo "[$(date "+%F %T")] ✅ 모든 replica ACTIVE" | tee -a "$LOG_FILE"
    break
  fi

  # 3) 비-Active가 남았지만 운영 ping이 연속 OK면 경고 로그 후 탈출
  if [ "$consecutive_ping_ok" -ge "$PING_OK_TARGET" ]; then
    echo "[$(date "+%F %T")] ⚠️ replica 비-Active가 ${count_not_active}개 남았지만, 코어 ping 연속 OK → 운영 가능으로 간주하고 진행" | tee -a "$LOG_FILE"
    # 문제 레플리카 후보 간단 덤프(상세 식별은 별도 수동 진단 권장)
    echo "$json" | tr -d '\n' | sed 's/{"replicas"/\n&/g' \
      | grep -E '"state":"(recovering|down|recovery_failed|inactive)"' -n \
      | head -n 20 | sed 's/^/  suspect: /' | tee -a "$LOG_FILE" || true
    break
  fi

  echo "[$(date "+%F %T")] … 아직 ACTIVE 아님 (비-Active replicas: $count_not_active), 대기 중" | tee -a "$LOG_FILE"
  sleep "$INTERVAL"
  elapsed=$((elapsed+INTERVAL))
  if [ "$elapsed" -ge "$MAX_WAIT_SEC" ]; then
    echo "⏱️ 최대 대기 초과" | tee -a "$LOG_FILE"
    break
  fi
done

##############################
# D. 코어별 ping 헬스 체크
##############################
echo "[$(date "+%F %T")] 📡 코어별 ping 확인..." | tee -a "$LOG_FILE"
for CORE in $CORE_LIST; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8983/solr/$CORE/admin/ping" || echo 000)
  if [ "$code" = "200" ]; then
    echo "✅ $CORE ping OK" | tee -a "$LOG_FILE"
  else
    echo "⚠️ $CORE ping 실패 (HTTP $code)" | tee -a "$LOG_FILE"
  fi
done

echo "[$DATE] ✅ Solr 재시작 및 리커버리 절차 완료." | tee -a "$LOG_FILE"
