#!/bin/bash

# 경로 설정
SOLR_BIN="/home/sysadmin/solr/bin/solr"
SOLR_DATA_DIR="/home/sysadmin/solr-data"
LOG_DIR="/home/sysadmin"
LOG_FILE="$LOG_DIR/solr_restart.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

echo "[$DATE] ▶️ Solr 재시작 작업 시작 [$HOSTNAME]" | tee -a "$LOG_FILE"

# Core 목록 자동 추출
CORE_LIST=$(curl -s "http://localhost:8983/solr/admin/cores?action=STATUS&wt=json" | \
  grep -o '"name":"[^"]*"' | cut -d':' -f2 | tr -d '"' | sort)

if [ -z "$CORE_LIST" ]; then
  echo "[$DATE] ⚠️ Core 목록을 찾을 수 없습니다. 종료합니다." | tee -a "$LOG_FILE"
  exit 1
fi

echo "[$DATE] 🔍 감지된 Core 목록: $CORE_LIST" | tee -a "$LOG_FILE"

# Solr 종료 시도
SOLR_PID=$(ps -ef | grep '[j]ava.*solr' | awk '{print $2}')
if [ -z "$SOLR_PID" ]; then
  echo "[$DATE] ℹ️ 현재 Solr 프로세스가 없습니다." | tee -a "$LOG_FILE"
else
  echo "[$DATE] 🔻 Solr stop 시도 중..." | tee -a "$LOG_FILE"
  $SOLR_BIN stop
  sleep 10
  SOLR_PID=$(ps -ef | grep '[j]ava.*solr' | awk '{print $2}')
  if [ -n "$SOLR_PID" ]; then
    echo "[$DATE] ⚠️ stop 실패. 강제 종료: PID=$SOLR_PID" | tee -a "$LOG_FILE"
    kill -9 "$SOLR_PID"
    sleep 5
  else
    echo "[$DATE] ✅ 정상적으로 종료됨." | tee -a "$LOG_FILE"
  fi
fi

# recovery 및 tlog 정리
echo "[$DATE] 🧹 임시 파일 정리 중..." | tee -a "$LOG_FILE"
for CORE in $CORE_LIST; do
  for DIRTYPE in recovery tlog; do
    TARGET_DIR="$SOLR_DATA_DIR/$CORE/data/$DIRTYPE"
    if [ -d "$TARGET_DIR" ]; then
      echo "삭제: $TARGET_DIR" | tee -a "$LOG_FILE"
      rm -rf "$TARGET_DIR"/*
    fi
  done
done

# write.lock 삭제
for CORE in $CORE_LIST; do
  LOCK_FILE="$SOLR_DATA_DIR/$CORE/data/index/write.lock"
  if [ -f "$LOCK_FILE" ]; then
    SOLR_PID=$(ps -ef | grep '[j]ava.*solr' | awk '{print $2}')
    if [ -z "$SOLR_PID" ]; then
      echo "[$DATE] 🔓 write.lock 제거: $LOCK_FILE" | tee -a "$LOG_FILE"
      rm -f "$LOCK_FILE"
    else
      echo "[$DATE] ⛔ write.lock 존재, Solr가 실행 중이므로 삭제하지 않음: $LOCK_FILE" | tee -a "$LOG_FILE"
    fi
  fi
done

# Solr 재시작
echo "[$DATE] 🔼 Solr start -cloud 수행 중..." | tee -a "$LOG_FILE"
$SOLR_BIN start -cloud
sleep 10

# 상태 확인
echo "[$DATE] 📡 상태 확인:" | tee -a "$LOG_FILE"
$SOLR_BIN status | tee -a "$LOG_FILE"

echo "[$DATE] ✅ Solr 재시작 완료." | tee -a "$LOG_FILE"
