#!/bin/bash

# 경로 설정
SOLR_BIN="/home/sysadmin/solr/bin/solr"
SOLR_DATA_DIR="/home/sysadmin/solr-data"
CORE_NAME="weblog_shard36_replica_n948"
LOG_DIR="/home/sysadmin"
LOG_FILE="$LOG_DIR/solr_restart.log"

DATE=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

echo "[$DATE] ▶️ Solr 재시작 작업 시작 [$HOSTNAME]" | tee -a "$LOG_FILE"

# Solr 실행 여부 확인
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

# 🧹 recovery 및 tlog 디렉토리 삭제
echo "[$DATE] 🧹 임시 파일 정리 중..." | tee -a "$LOG_FILE"
find "$SOLR_DATA_DIR" -type d \( -name 'recovery' -o -name 'tlog' \) -exec sh -c '
  echo "삭제: $1" | tee -a "'"$LOG_FILE"'"
  rm -rf "$1"/*
' sh {} \;

# 🔓 write.lock 조건부 삭제
LOCK_FILE="$SOLR_DATA_DIR/$CORE_NAME/data/index/write.lock"
if [ -f "$LOCK_FILE" ]; then
  SOLR_PID=$(ps -ef | grep '[j]ava.*solr' | awk '{print $2}')
  if [ -z "$SOLR_PID" ]; then
    echo "[$DATE] 🔓 write.lock 파일 제거: $LOCK_FILE" | tee -a "$LOG_FILE"
    rm -f "$LOCK_FILE"
  else
    echo "[$DATE] ⛔ write.lock 파일이 존재하지만 Solr가 실행 중이므로 삭제하지 않음." | tee -a "$LOG_FILE"
  fi
fi

# Solr 재시작
echo "[$DATE] 🔼 Solr start -cloud 수행 중..." | tee -a "$LOG_FILE"
$SOLR_BIN start -cloud
sleep 10

# 상태 확인
echo "[$DATE] 📡 상태 확인:" | tee -a "$LOG_FILE"
$SOLR_BIN status | tee -a "$LOG_FILE"

echo "[$DATE] ✅ Solr 재시작 완료." | tee -a "$LOG_FILE"
