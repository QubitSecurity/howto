# Apache Solr 멀티 인스턴스(포트별) 운영 

**타깃 환경:** Solr 9.9.0 · **OpenJDK 21** · 단일 대형 서버(512GB RAM 이상, SSD 14TB) · **RF=2(1 master/1 replica)** · `sysadmin` 일반 사용자로 운영

---

## 1) 설계

* **포트별 멀티 인스턴스**: 한 서버당 16개 인스턴스 (포트 8983~8998)
* **자원 배분**
  * JVM HEAP: 인스턴스당 24GB
  * OS Page Cache: 총 메모리의 절반 이상(>300GB) 남겨 Lucene MMap 성능 활용. 16개 인스터스 구성 시, `총 384GB 사용 (예상)`
* **ZK**: 별도 3대 ZooKeeper 앙상블 클러스터링
* **보안**: 포트는 1024 이상으로 바인딩하여 root 불필요. 방화벽/프록시로 외부 노출을 제어.

---

## 2) 인스턴스 포트 구성

| Port | 홈 디렉터리           |  HEAP | 비고           |
| ---: | ---------------- | ----: | ------------ |
| 8983 | `/opt/solr-8983` | 24 GB | 리더/팔로워 모두 허용 |
| 8984 | `/opt/solr-8984` | 24 GB |              |
| 8985 | `/opt/solr-8985` | 24 GB |              |
...
| 8996 | `/opt/solr-8990` | 24 GB |              |
| 8997 | `/opt/solr-8990` | 24 GB |              |
| 8998 | `/opt/solr-8990` | 24 GB |              |
|  |  | 384 GB | 총 Heap Size 할당 (예정)             |

---

## 3) 개별 Solr 인스턴스 구조 
### 3.0 공통 실행 바이너리 심볼릭 링크
```
ln -s /opt/solr-9.9.0/ /opt/solr
```

### 3.1 개별 실행 디렉토리 구조
```
/opt
/opt/solr -> /opt/solr-9.9.0 # solr 실행 기본 바이너리 (내부 구조 유지 /opt/solr9.9.0 심볼릭 링크)
/opt/solr-89XX/              # 인스턴스 홈(소유자: sysadmin)
  data/                      # cores, tlog, index
  logs/                      # 로그
  run/                       # PID/임시
  env                        # 인스턴스 환경설정 (포트/heap 등)
  start.sh                   # 실행 스크립트
  stop.sh                    # 종료 스크립트
```

### 3.2 개별 디렉토리 생성
```bash
# sysadmin 계정으로
install -d -m 0755 /opt/solr-{8983..8998}/{data,logs,run}
# 포트별로 반복 (8984~8998)
```

### 3.3 개별 실행 env 파일 생성(/opt/solr-89XX/env)
```
# ===== [필수 기본 설정] =====
SOLR_PORT=89XX

# Solr 기본 경로 Prefix
SOLR_BASE="/opt/solr-${SOLR_PORT}"

# ===== [경로 설정] =====
SOLR_HOME="${SOLR_BASE}/data"
SOLR_LOGS_DIR="${SOLR_BASE}/logs"
SOLR_PID_DIR="${SOLR_BASE}/run"
SOLR_HOST=$(hostname -I | awk '{print $1}')
ZK_HOST="zk1:2181,zk2:2181,zk3:2181"
SOLR_JETTY_HOST=0.0.0.0

# ===== [모듈 설정] =====
SOLR_MODULES="scripting"

# ===== [JVM/튜닝 설정] =====
SOLR_HEAP="24g"
SOLR_JAVA_STACK="512k"

# SOLR_OPTS 초기화
SOLR_OPTS=""

#SOLR_OPTS="$SOLR_OPTS -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+ParallelRefProcEnabled"
#SOLR_OPTS="$SOLR_OPTS -XX:+AlwaysPreTouch -XX:+PerfDisableSharedMem"
SOLR_OPTS="$SOLR_OPTS -Djava.io.tmpdir=${SOLR_PID_DIR}/tmp"
SOLR_OPTS="$SOLR_OPTS -Dsolr.directoryFactory=solr.MMapDirectoryFactory"
SOLR_OPTS="$SOLR_OPTS -Dsolr.autoSoftCommit.maxTime=2000"

# ===== [품질/운영 설정] =====
UMASK=0022
```
※ 요구된 solr 실행 옵션
```
SOLR_OPTS="$SOLR_OPTS -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+ParallelRefProcEnabled"
SOLR_OPTS="$SOLR_OPTS -XX:+AlwaysPreTouch -XX:+PerfDisableSharedMem"
위 실행 옵션 중, 나머지는 기본 실행 시 기동됨. MaxGCPauseMillis 기본 값은 250으로 수정한다면, /opt/solr/bin/solr 내에서 수동 변경
```

### 3.3 실행 / 종료 스크립트 작성
실행(/opt/solr-89XX/start.sh)
```
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./env

# ===== [디렉터리 준비] =====
mkdir -p "$SOLR_HOME" "$SOLR_LOGS_DIR" "$SOLR_PID_DIR" "$SOLR_PID_DIR/tmp"

# ===== [Solr 실행] =====
exec /opt/solr/bin/solr start -c \
  --host "$SOLR_HOST" \
  -p "$SOLR_PORT" \
  --host "$SOLR_HOST" \
  --solr-home "$SOLR_HOME" \
  --data-home "$SOLR_HOME" \
  -z "$ZK_HOST" \
  -m "$SOLR_HEAP" \
  --jvm-opts "-Dlog.dir=${SOLR_LOGS_DIR} \
              -Dsolr.log.dir=${SOLR_LOGS_DIR} \
              -Dsolr.port=${SOLR_PORT} \
              -Dsolr.solr.home=${SOLR_HOME} \
              -Dsolr.pid.dir=${SOLR_PID_DIR} \
              -Dsolr.jetty.host=$SOLR_JETTY_HOST \
              -Dsolr.modules=${SOLR_MODULES} \
              -Dsolr.allow.unsafe.resourceloading=true" \
  2>&1 | tee "${SOLR_LOGS_DIR}/solr-startup.log"
```
종료(/opt/solr-89XX/stop.sh)
```
#!/usr/bin/env bash
set -euo pipefail
source ./env
/opt/solr/bin/solr stop -p "$SOLR_PORT" || true
```
---

## 4) systemd **사용자 단위**로 관리 (자동 시작, root 불필요)

### 4.1 **linger 허용**(한 번만; 이미 되어 있으면 생략)
확인 명령어
```
loginctl list-users
```
허용 명령어
```bash
loginctl enable-linger sysadmin
```

### 4.2 **유닛 템플릿** `~/.config/systemd/user/solr@.service`
디렉토리 생성
```
mkdir -p ~/.config/systemd/user/
```

service 파일 생성(`~/.config/systemd/user/solr@.service`)
```
[Unit]
Description=Solr (%i) user instance
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
WorkingDirectory=/opt/solr-%i
EnvironmentFile=/opt/solr-%i/env
ExecStart=/opt/solr-%i/start.sh
ExecStop=/opt/solr-%i/stop.sh
PIDFile=/opt/solr-%i/run/solr-%i.pid
Restart=on-failure
LimitNOFILE=1048576

[Install]
WantedBy=default.target
```
### 4.3 서비스 등록

```bash
systemctl --user daemon-reload
systemctl --user enable --now solr@89XX
# 필요 포트 반복: 8984..8990
```

관련 명령어
```
서비스 확인 명령어
systemctl --user list-units --type=service | grep solr

개별 서비스 삭제(안전)
systemctl --user stop solr@89XX
systemctl --user disable solr@89XX
systemctl --user stop solr@89XX
systemctl --user reset-failed solr@89XX.service

데몬 리로드 (메모리 상 유닛 테이블 새로고침)
systemctl --user daemon-reload
```

### 4.4 실행 / 종료 
실행
```
systemctl --user start solr@89XX
```
종료
```
systemctl --user stop solr@89XX
```




