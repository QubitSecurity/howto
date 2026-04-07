# Apache ZooKeeper 3-Node 설치/운영 가이드 (v3.9.4)

**대상:** Solr 9.9.0 클러스터용 코디네이션 서비스 · **설치 경로:** `/home/sysadmin` · **JDK:** OpenJDK 21 · **구성:** 3-노드 앙상블

---

## 1) 개요 & 권장 설계

* **버전:** Apache ZooKeeper **3.9.4** (Solr 9.9.0와 호환)
* **역할:** SolrCloud의 메타데이터 저장/리더 선출/클러스터 상태 관리
* **토폴로지:** 3 노드(과반수 2), 각 노드는 전용 데이터/로그 디렉터리 보유
* **포트:** `2181`(client), `2888`(quorum), `3888`(leader election)

> 표기 편의를 위해 노드 이름을 `zk1`, `zk2`, `zk3`라 가정합니다. 실제 호스트명/IP로 바꿔 적용하세요.

---

## 2) 디렉터리 레이아웃 (모든 노드 동일)

```
/home/sysadmin/zookeeper-3.9.4/     # ZK 소프트웨어 (압축 해제)
/home/sysadmin/zk/zk1/{data,logs}   # zk1의 데이터/로그
/home/sysadmin/zk/zk2/{data,logs}   # zk2의 데이터/로그
/home/sysadmin/zk/zk3/{data,logs}   # zk3의 데이터/로그
```

> 한 대에 여러 노드(랩/개발)로 올릴 때 위처럼 `zk1/zk2/zk3`를 한 서버에 만들 수 있습니다. 실운영은 **물리/가용영역 분리**를 권장합니다.

---

## 3) 설치 (모든 노드 공통)

```bash
# 1) 압축 해제 (이미 다운로드돼 있다면 생략)
cd /home/sysadmin
tar -xf apache-zookeeper-3.9.4-bin.tar.gz
ln -sfn apache-zookeeper-3.9.4-bin zookeeper-3.9.4   # 선택: 버전 심볼릭 링크

# 2) 데이터/로그 디렉터리 준비 (해당 노드에서 자신의 것만)
install -d -m 0755 /home/sysadmin/zk/zk1/{data,logs}
install -d -m 0755 /home/sysadmin/zk/zk2/{data,logs}
install -d -m 0755 /home/sysadmin/zk/zk3/{data,logs}
```

---

## 4) `myid` 작성 (노드별 고유 ID)

각 노드에서 **자신의 data 디렉터리**에 ID 파일을 만듭니다.

* zk1:

  ```bash
  echo 1 > /home/sysadmin/zk/zk1/data/myid
  ```
* zk2:

  ```bash
  echo 2 > /home/sysadmin/zk/zk2/data/myid
  ```
* zk3:

  ```bash
  echo 3 > /home/sysadmin/zk/zk3/data/myid
  ```

> ID(1/2/3)는 아래 `server.N=` 설정의 `N`과 반드시 일치해야 합니다.

---

## 5) 설정 파일(`zoo.cfg`) 템플릿

각 노드에 **자신의 zoo.cfg**를 만듭니다. 기본 경로는 `/home/sysadmin/zookeeper-3.9.4/conf/zoo.cfg` 입니다.
(노드마다 `dataDir`/`dataLogDir` 위치만 다르고 나머지는 동일합니다)

### zk1의 `zoo.cfg` 예시

```properties
# 기본
tickTime=2000
initLimit=10
syncLimit=5

# 저장소 경로
dataDir=/home/sysadmin/zk/zk1/data
dataLogDir=/home/sysadmin/zk/zk1/logs

# 클라이언트 포트
clientPort=2181
# 모든 NIC에서 수신 (필요시 특정 IP로 제한)
clientPortAddress=0.0.0.0

# 관리/보안/운영
standaloneEnabled=false
admin.enableServer=true
quorumListenOnAllIPs=true
4lw.commands.whitelist=ruok,stat,srvr,envi,cons,mntr,conf
autopurge.snapRetainCount=10
autopurge.purgeInterval=12

# 메트릭(선택)
metricsProvider.className=org.apache.zookeeper.metrics.prometheus.PrometheusMetricsProvider
metricsProvider.httpPort=7000
metricsProvider.exportJvmInfo=true

# 서버 목록 (host:quorum:leaderElection)
server.1=zk1:2888:3888
server.2=zk2:2888:3888
server.3=zk3:2888:3888
```

> zk2/zk3는 `dataDir`/`dataLogDir`와 `clientPort`만 동일하게 두고 **myid만 해당 값(2/3)** 이면 됩니다.
> 한 서버에 3노드를 올리는 **랩 모드**라면 `clientPort=2181/2182/2183`, `metricsProvider.httpPort=7000/7001/7002` 처럼 포트를 달리 지정하세요.

---

## 6) 실행 스크립트 (노드별)

경로: `/home/sysadmin/zookeeper-3.9.4/bin` (모든 명령은 `sysadmin`으로 실행)

### 시작

```bash
# zk1 노드에서
/home/sysadmin/zookeeper-3.9.4/bin/zkServer.sh start \
  /home/sysadmin/zookeeper-3.9.4/conf/zoo.cfg

# zk2/zk3에서도 각자 실행
```

### 상태 확인

```bash
/home/sysadmin/zookeeper-3.9.4/bin/zkServer.sh status \
  /home/sysadmin/zookeeper-3.9.4/conf/zoo.cfg
```

### 중지/재시작

```bash
/home/sysadmin/zookeeper-3.9.4/bin/zkServer.sh stop   /home/sysadmin/zookeeper-3.9.4/conf/zoo.cfg
/home/sysadmin/zookeeper-3.9.4/bin/zkServer.sh restart/home/sysadmin/zookeeper-3.9.4/conf/zoo.cfg
```

---

## 7) systemd (사용자 단위) 유닛

**부팅 자동시작**과 모니터링을 위해 user-mode systemd를 권장합니다.

1. (최초 1회) linger 허용

```bash
loginctl enable-linger sysadmin
```

2. 유닛 파일들 생성: `~/.config/systemd/user/`

* `zookeeper@.service` (템플릿)

  ```ini
  [Unit]
  Description=ZooKeeper %i (user mode)
  After=network-online.target
  Wants=network-online.target

  [Service]
  Type=forking
  User=%u
  Environment=ZK_HOME=/home/sysadmin/zookeeper-3.9.4
  Environment=CONF=/home/sysadmin/zookeeper-3.9.4/conf/%i.cfg
  ExecStart=%h/zookeeper-3.9.4/bin/zkServer.sh start  ${CONF}
  ExecStop=%h/zookeeper-3.9.4/bin/zkServer.sh stop   ${CONF}
  ExecReload=%h/zookeeper-3.9.4/bin/zkServer.sh restart ${CONF}
  Restart=on-failure
  LimitNOFILE=1048576

  [Install]
  WantedBy=default.target
  ```

* 각 노드용 conf 심플 링크(또는 별도 파일):

  ```
  ln -s /home/sysadmin/zookeeper-3.9.4/conf/zoo.cfg  /home/sysadmin/zookeeper-3.9.4/conf/zk1.cfg
  ln -s /home/sysadmin/zookeeper-3.9.4/conf/zoo2.cfg /home/sysadmin/zookeeper-3.9.4/conf/zk2.cfg
  ln -s /home/sysadmin/zookeeper-3.9.4/conf/zoo3.cfg /home/sysadmin/zookeeper-3.9.4/conf/zk3.cfg
  ```

  > `zoo2.cfg`, `zoo3.cfg`는 zk2/zk3 설정 파일 이름입니다. 파일명을 자유롭게 쓰되 `zkN.cfg`와 매칭만 맞추면 됩니다.

3. 기동/등록

```bash
systemctl --user daemon-reload
systemctl --user enable --now zookeeper@zk1
systemctl --user enable --now zookeeper@zk2
systemctl --user enable --now zookeeper@zk3
```

---

## 8) Solr용 chroot 생성 & 연결 테스트

### (선택) `/solr` chroot 생성

```bash
/home/sysadmin/zookeeper-3.9.4/bin/zkCli.sh -server zk1:2181
# 프롬프트에서:
create /solr ""
quit
```

> SolrCloud를 `zk1:2181,zk2:2181,zk3:2181/solr`로 붙이면 `/solr` 하위에 메타데이터가 저장됩니다.

### 간단 헬스체크(4lw)

```bash
# 간단 응답
echo ruok | nc zk1 2181 ; echo
# 서버 상태
echo srvr | nc zk1 2181
# 클라이언트 연결
echo cons | nc zk1 2181 | head
```

---

## 9) 방화벽/네트워크

* **필수 오픈(노드 간/클라이언트):**

  * 클라이언트: `2181/tcp`
  * 쿼럼: `2888/tcp`
  * 리더 선출: `3888/tcp`
* 운영/모니터링용(선택): 메트릭 `7000/tcp` (위 설정을 켰을 경우)

---

## 10) 자동 정리(Autopurge) & 백업

* `autopurge.purgeInterval=12`(시간) & `autopurge.snapRetainCount=10` 으로 **스냅샷/로그 자동 정리**.
* 정기 백업: `dataDir` 스냅샷(파일시스템 스냅샷 선호). 앙상블 정지 없이 **각 노드를 순차적으로** 백업하세요.

---

## 11) 업그레이드 절차(롤링)

1. 새로운 ZK 바이너리를 `/home/sysadmin`에 배치 후 심링크 교체(예: `zookeeper-3.9.5` → `zookeeper-3.9.4` 링크 전환).
2. **한 노드씩** `systemctl --user restart zookeeper@zkN` (과반수 유지).
3. 각 재시작 후 `srvr/cons/mntr`로 정상 확인.

---

## 12) 트러블슈팅 핸드북

* **status가 `error contacting service`**
  → `dataDir`/`myid`/`server.N` 일치 여부, 포트 충돌, 호스트네임 DNS 확인.
* **리더 선출 반복**
  → `syncLimit` 증가, 네트워크 지연/패킷 드롭 점검, 서버 시간 싱크(Chrony).
* **스냅샷/로그 폭증**
  → `autopurge.*` 값 재확인, 디스크 모니터링/알람 설정.
* **클라이언트 세션 누적**
  → `maxClientCnxns`(필요 시 설정) 및 Solr 노드 수 대비 커넥션 수 점검.

---

## 13) Solr 연결 문자열 예시

Solr 노드의 `env` 또는 `solr.in.sh`에서:

```
ZK_HOST="zk1:2181,zk2:2181,zk3:2181/solr"
```

> `/solr` chroot를 쓰지 않을 경우 `...:2181` 형태만 사용합니다.

---

### 마무리

이 문서대로 적용하면 **/home/sysadmin** 트리 아래에서 **OpenJDK 21 + ZooKeeper 3.9.4**의 3-노드 앙상블을 **일반 사용자 권한**으로 안정적으로 운영할 수 있습니다.
