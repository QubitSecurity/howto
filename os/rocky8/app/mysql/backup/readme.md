## 백업 DB SQL 파일을 원격지 전송
- ssh 기반으로 원격지 로그 저장 시스템 연결
- 원격 로그 저장 시스템으로 주기적 로그 전송
- 전송 구조
```mermaid
graph LR;
    DB_Server[DB 서버(PLURA 내)] --(SSH-Internal Network)--> Internal_System[중계 서버(PLURA 내)] --(SSH-External Network)--> External_System[외부 저장 서버]
```

### 1. SSH Key 기반 중계 서버 및 외부 서버 연결
```
SSH Key 생성(DB 서버, 중계 서버)
ssh-keygen -t rsa -b 4096

SSH Key 전송(DB 서버 -> 중계 서버)
ssh-copy-id [backup_user]@[중계 서버 IP] #중계 서버 Backup User

SSH Key 전송(중계 서버 -> 외부 저장 서버)
ssh-copy-id [external_backup_user]@[외부 저장 서버 IP] # #외부 저장 서버 Backup User
```

### 2. DB SQL 파일 전송(DB 서버 -> 중계 서버)
```
DB 서버 - DB SQL 파일 전송 쉘 작성
vi /root/send_mysql.sh

#!/bin/bash
SRC_DIR="/PATH" #DB 서버 내 저장된 로그 경로
DEST_USER="backup_user"    #중계 서버m Backup User
DEST_HOST="xxx.xxx.xxx.xxx" #중계 서버 IP
DEST_DIR="/PATH" #중계 서버 로그 저장 경로(Permission 확인)
SSH_PORT=22
 
# 최신 all_backup 기준 최신 날짜 데이텉 prefix 추출
LATEST_PREFIX=$(ls -t ${SRC_DIR}/*dump_plura240_all_backup.sql | head -1 | cut -d'-' -f1)
echo "Latest prefix: ${LATEST_PREFIX}"
 
# 파일 없을 경우 종료
if [ -z "$LATEST_PREFIX" ]; then
    echo "No backup files found."
    exit 1
fi
 
echo "Start transfer..."
 
# filter DB 만 전송
scp -P ${SSH_PORT} \
    -o StrictHostKeyChecking=no \
    ${LATEST_PREFIX}*filter*  \
    ${DEST_USER}@${DEST_HOST}:${DEST_DIR}
 
echo "Done."

crontab 작성
crontab -e
10 1 * * * /root/send_mysql.sh >> /root/send.log /dev/null 2>&1
```

### 3. 외부 네트워크 전송(중계 서버 -> 외부 저장 서버)
```
중계 서버 - 외부 네트워크 DB SQL 파일 전송 쉘 작성
vi /root/send_external.sh

#!/bin/bash

SRC_DIR="/PATH" #중계 서버 내 저장된 로그 경로
DEST_USER="external_backup_user"    #외부 저장 서버 Backup User
DEST_HOST="xxx.xxx.xxx.xxx" #외부 저장 서버 IP
DEST_DIR="/PATH" #외부 저장 서버 로그 저장 경로(Permission 확인)
SSH_PORT=22

echo "==== Transfer Script Start ===="

# 1. DB 파일 존재 여부 확인 (에러 없이 체크)
FILES=$(find ${SRC_DIR} -maxdepth 1 -type f -name "*.sql")

if [ -z "$FILES" ]; then
    echo "No DB files found. Skip transfer."
    exit 0
fi

echo "DB files found. Start transfer..."

# 2. 전송
scp -P ${SSH_PORT} \
    -o StrictHostKeyChecking=no \
    ${SRC_DIR}/*.sql \
    ${DEST_USER}@${DEST_HOST}:${DEST_DIR}

# 3. 전송 결과 확인
if [ $? -eq 0 ]; then
    echo "Transfer completed successfully."

    # 4. 5일 이상 지난 파일 삭제
    echo "Cleaning up old files (older than 1 hour)..."

    find ${SRC_DIR} -type f -name "*.sql" -mtime +5 -exec rm -f {} \;

    echo "Cleanup completed."
else
    echo "Transfer failed!"
    exit 1
fi

echo "Done."

crontab 작성
crontab -e
15 1 * * * /root/send_external.sh >> /root/send_external.log /dev/null 2>&1
```



