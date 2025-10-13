# Apache Solr 멀티 인스턴스(포트별) 운영 가이드

**타깃 환경:** Solr 9.x (예: 9.9) · **OpenJDK 21** · 단일 대형 서버(512GB RAM, SSD 14TB) · **RF=2(1 master/1 replica)** · `sysadmin` 일반 사용자로 운영

---

## 1) 설계 개요

* **포트별 멀티 인스턴스**: 한 서버당 6–8개 인스턴스 권장 (예: `8983–8990`).
* **자원 배분**

  * JVM HEAP: 인스턴스당 20–24GB 권장.
  * OS Page Cache: 총 메모리의 절반 이상(>300GB) 남겨 Lucene MMap 성능 활용.
* **스토리지**: 인스턴스별 데이터 디렉터리를 다른 LV/디스크에 분산(가능 시). XFS + `noatime` 권장.
* **ZK**: 별도 3~5대 ZooKeeper 앙상블. 모든 노드는 동일 ZK 커넥션 사용(예: `zk1,zk2,zk3/solr`).
* **보안**: 포트는 1024 이상으로 바인딩하여 root 불필요. 방화벽/프록시로 외부 노출을 제어.

---

## 2) 인스턴스 포트 계획 (예시)

| Port | 홈 디렉터리           |  HEAP | 비고           |
| ---: | ---------------- | ----: | ------------ |
| 8983 | `/opt/solr-8983` | 24 GB | 리더/팔로워 모두 허용 |
| 8984 | `/opt/solr-8984` | 24 GB |              |
| 8985 | `/opt/solr-8985` | 24 GB |              |
| 8986 | `/opt/solr-8986` | 24 GB |              |
| 8987 | `/opt/solr-8987` | 24 GB |              |
| 8988 | `/opt/solr-8988` | 24 GB |              |
| 8989 | `/opt/solr-8989` | 24 GB |              |
| 8990 | `/opt/solr-8990` | 24 GB |              |

---

## 3) Java/Solr 버전 & JVM 옵션 (OpenJDK 21)

* **Solr 9.x + OpenJDK 21** 조합으로 운영합니다.
* JVM: **G1GC**(안정) 기본. 아주 큰 힙/짧은 지연을 원하면 **ZGC**도 선택 가능(JDK 21).
* 공통 옵션(예시, `solr.in.sh` 또는 인스턴스 `env`에서 `SOLR_OPTS`로 주입):

```bash
SOLR_HEAP="24g"                     # 포트별 조정
SOLR_JAVA_STACK="512k"
# G1GC (권장)
SOLR_OPTS="$SOLR_OPTS -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+ParallelRefProcEnabled"
# 메모리/성능
SOLR_OPTS="$SOLR_OPTS -XX:+AlwaysPreTouch -XX:+PerfDisableSharedMem"
# 임시 디렉터리(인스턴스별로 격리)
SOLR_OPTS="$SOLR_OPTS -Djava.io.tmpdir=/var/tmp/solr"
# Solr 튜닝
SOLR_OPTS="$SOLR_OPTS -Dsolr.autoSoftCommit.maxTime=2000"
SOLR_OPTS="$SOLR_OPTS -Dsolr.directoryFactory=solr.MMapDirectoryFactory"
```

> **ZGC 사용 시**(선택):
> `-XX:+UseZGC -XX:ZUncommitDelay=300` 로 교체하고 G1 관련 플래그는 제거하세요.
> 대형 힙(30GB+)에서 GC 지연을 더 짧게 가져가야 할 때 유리합니다.

---

## 4) 권장 레이아웃(사용자 소유, root 불필요)

**조건**

* **root 없이 `sysadmin` 계정만으로** 인스턴스별 디렉터리를 **`/opt/solr-PORT`** 아래에 두고 전부 관리
* 포트가 1024 이상이면 root 권한 없이 바인딩 가능

**디렉터리 구조(예: 8983)**

```
/opt/solr-8983/             # 인스턴스 홈(소유자: sysadmin)
  bin/                      # 공통 Solr 바이너리(심볼릭 링크 또는 복사)
  data/                     # cores, tlog, index
  logs/                     # 로그
  run/                      # PID/임시
  env                       # 인스턴스 환경설정 (포트/heap 등)
```

> 공통 바이너리는 `/opt/solr/current`에 두고, 각 인스턴스의 `bin -> /opt/solr/current/bin` 심볼릭 링크로 재사용하면 업그레이드가 쉽습니다.

**생성 예**

```bash
# sysadmin 계정으로
install -d -m 0755 /opt/solr-{8983..8990}/{data,logs,run}
ln -s /opt/solr/current/bin /opt/solr-8983/bin
# 포트별로 반복 (8984~8990)
```

---

## 5) 인스턴스 환경파일 예 (`/opt/solr-8983/env`)

```bash
# 필수
SOLR_PORT=8983
SOLR_HOME="/opt/solr-8983/data"
SOLR_LOGS_DIR="/opt/solr-8983/logs"
SOLR_PID_DIR="/opt/solr-8983/run"
SOLR_HOST="$(hostname -f)"
ZK_HOST="zk1:2181,zk2:2181,zk3:2181/solr"

# JVM/튜닝 (OpenJDK 21)
SOLR_HEAP="24g"
SOLR_JAVA_STACK="512k"
SOLR_OPTS="$SOLR_OPTS -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+ParallelRefProcEnabled"
SOLR_OPTS="$SOLR_OPTS -XX:+AlwaysPreTouch -XX:+PerfDisableSharedMem"
SOLR_OPTS="$SOLR_OPTS -Djava.io.tmpdir=/opt/solr-8983/run/tmp"
SOLR_OPTS="$SOLR_OPTS -Dsolr.directoryFactory=solr.MMapDirectoryFactory"
SOLR_OPTS="$SOLR_OPTS -Dsolr.autoSoftCommit.maxTime=2000"

# 품질/운영
UMASK=0022
```

---

## 6) 시작/중지 스크립트 (인스턴스 로컬, root 불필요)

**`/opt/solr-8983/start.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source ./env
mkdir -p "$SOLR_HOME" "$SOLR_LOGS_DIR" "$SOLR_PID_DIR" "$SOLR_PID_DIR/tmp"
exec /opt/solr-8983/bin/solr start -cloud \
  -p "$SOLR_PORT" -s "$SOLR_HOME" -z "$ZK_HOST" -h "$SOLR_HOST" \
  -m "$SOLR_HEAP" \
  -Dlog.dir="$SOLR_LOGS_DIR" \
  -Dsolr.log.dir="$SOLR_LOGS_DIR" \
  -Dsolr.port="$SOLR_PORT" \
  -Dsolr.solr.home="$SOLR_HOME" \
  -Dsolr.pid.dir="$SOLR_PID_DIR"
```

**`/opt/solr-8983/stop.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
source /opt/solr-8983/env
/opt/solr-8983/bin/solr stop -p "$SOLR_PORT" || true
```

> 8984~8990도 `bin` 링크만 맞추고 `env`의 포트/경로만 바꿔 복제하면 됩니다.

---

## 7) systemd **사용자 단위**로 관리 (자동 시작, root 불필요)

1. **linger 허용**(한 번만; 이미 되어 있으면 생략)

```bash
loginctl enable-linger sysadmin
```

2. **유닛 템플릿** `~/.config/systemd/user/solr@.service`

```ini
[Unit]
Description=Solr (%i) user instance
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
User=%u
WorkingDirectory=/opt/solr-%i
EnvironmentFile=/opt/solr-%i/env
ExecStart=/opt/solr-%i/bin/solr start -cloud -p ${SOLR_PORT} -s ${SOLR_HOME} -z ${ZK_HOST} -h ${SOLR_HOST} -m ${SOLR_HEAP} -Dlog.dir=${SOLR_LOGS_DIR} -Dsolr.pid.dir=${SOLR_PID_DIR}
ExecStop=/opt/solr-%i/bin/solr stop -p ${SOLR_PORT}
PIDFile=%h/.cache/solr-%i.pid
Restart=on-failure
LimitNOFILE=1048576

[Install]
WantedBy=default.target
```

3. **실행**

```bash
systemctl --user daemon-reload
systemctl --user enable --now solr@8983
# 필요 포트 반복: 8984..8990
```

---

## 8) 컬렉션 생성 가이드 (RF=2)

* 샤드 수는 전체 노드 수(서버×인스턴스)의 약수/배수로 선정(균등 배치).
* **같은 shard의 replica는 서로 다른 물리 서버**로 가도록 배치(필수 운영 원칙).
* 생성 예:

```bash
curl -s "http://nodeA:8983/solr/admin/collections" --data '
  action=CREATE&
  name=weblog&
  numShards=24&
  replicationFactor=2&
  maxShardsPerNode=2'
```

> Solr 9에서는 autoscaling policy가 제거됨. 필요 시 **createNodeSet** 또는 placement 플러그인/노드 태그 전략으로 물리 분산을 보장하세요.

---

## 9) 퍼미션/보안 체크리스트

* `/opt/solr-*` 전부 **sysadmin:sysadmin** 소유, 0755(데이터/로그는 0750 가능)
  `chown -R sysadmin:sysadmin /opt/solr-8983`
* 포트 1024 이상 사용 → root 불필요.
* 방화벽/리버스프록시(Nginx/Haproxy)로 인바운드 접근 제어.
* 파일 디스크립터: `LimitNOFILE=1048576`(systemd) 또는 셸에서 `ulimit -n 1048576`.
* XFS + `noatime`, readahead 256–512 검토, 주기적 TRIM.
* 커널: `vm.swappiness=1` 등 메모리 압박 최소화.

---

## 10) 운영 팁

* **커밋 전략**: soft commit 1–2s, hard commit(새 서처 오픈)은 분 단위.
* **머지 제어**: `TieredMergePolicy` 파라미터(예: `segmentsPerTier`)로 피크 IO 완화.
* **백업**: Repository API(증분) + S3/NAS 스케줄링.
* **모니터링**: `/solr/admin/metrics` + Prometheus Exporter, JVM/GC/쿼리/핫스레드 추적.
* **장애 복구**: `autoAddReplicas=true` 컬렉션 속성 검토(자동 보강).

---

### 결론

**OpenJDK 21 + Solr 9.x** 환경에서, `/opt/solr-PORT` 단일 트리로 **일반 사용자(`sysadmin`)가 포트별 멀티 인스턴스**를 운영하면 업그레이드/확장이 단순하고 안전합니다. 위 템플릿을 8983~8990으로 복제하고, 샤드/레플리카 배치를 물리적으로 분리하면 대형 서버에서도 높은 안정성과 성능을 확보할 수 있습니다.
