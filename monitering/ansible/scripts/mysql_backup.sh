#!/bin/bash

# 설정값
BACKUP_DIR="/var/backups/mysql"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
MYSQL_USER="root"
MYSQL_PASSWORD=""
MYSQL_HOST="localhost"
MYSQL_PORT="3306"
DB_NAME=""  # 비워두면 전체 DB 백업

# 로그
LOG_FILE="$BACKUP_DIR/backup_$DATE.log"
mkdir -p "$BACKUP_DIR"

# 파일 이름 설정
if [ -z "$DB_NAME" ]; then
    BACKUP_FILE="$BACKUP_DIR/all_databases_$DATE.sql.gz"
    TARGET="--all-databases"
else
    BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_$DATE.sql.gz"
    TARGET="$DB_NAME"
fi

echo "[$DATE] ▶️ MySQL 백업 시작" | tee -a "$LOG_FILE"

# 백업 수행
mysqldump -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -P "$MYSQL_PORT" \
    --routines --events --single-transaction --quick --set-gtid-purged=OFF $TARGET 2>>"$LOG_FILE" | gzip > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "[$DATE] ✅ 백업 성공: $BACKUP_FILE" | tee -a "$LOG_FILE"
else
    echo "[$DATE] ❌ 백업 실패" | tee -a "$LOG_FILE"
    echo -e "[ALERT] MySQL 백업 실패\n날짜: $DATE\n대상: $DB_NAME\n로그 파일: $LOG_FILE" \
        | mail -s "[ALERT] MySQL 백업 실패" joo@qubitsec.com
    exit 2
fi
