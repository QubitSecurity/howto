# Apache ZooKeeper 3.9.4 → **3.9.5** 롤링 업그레이드 가이드

**대상:** Solr 9.9.x 클러스터용 ZK 3-노드 앙상블 · **현재:** 3.9.4 · **목표:** 3.9.5 · **설치 경로:** `/home/sysadmin` · **JDK:** OpenJDK 21 · **무중단(near-zero downtime) 롤링 전략**

---

## 0) 요약 체크리스트

* [ ] **사전 점검:** 과반수(2/3) 정상, 디스크 여유, 시간 동기화(chrony) 정상
* [ ] **새 버전 전개:** `/home/sysadmin/apache-zookeeper-3.9.5-bin` 압축 해제
* [ ] **심링크 전략 정리:** `zookeeper`(또는 `zookeeper-current`) 심링크 전환 방식 권장
* [ ] **롤링 재시작:** `zk2 → zk3 → zk1` 같은 순서로 **한 노드씩** 재시작(항상 과반수 유지)
* [ ] **검증:** `ruok/srvr/mntr` 4lw, 클라이언트 연결 수, Solr 접속 확인
* [ ] **정리:** systemd 유닛(필요 시) 갱신, 로그/스냅숏 보존 정책 확인
* [ ] **롤백 플랜:** 심링크/유닛을 3.9.4로 즉시 복귀 가능

---

## 1) 현재 디렉터리/유닛 전제(기존 가이드 기준)

* 소프트웨어: `/home/sysadmin/zookeeper-3.9.4` (혹은 `apache-zookeeper-3.9.4-bin`)
* 데이터/로그(예시):

  * `zk1`: `/home/sysadmin/zk/zk1/{data,logs}` (myid=1)
  * `zk2`: `/home/sysadmin/zk/zk2/{data,logs}` (myid=2)
  * `zk3`: `/home/sysadmin/zk/zk3/{data,logs}` (myid=3)
* systemd(user) 템플릿(예시): `~/.config/systemd/user/zookeeper@.service`

  * 과거 문서대로면 `Environment=ZK_HOME=/home/sysadmin/zookeeper-3.9.4`

> **권장:** 이번 업그레이드 시 **영구적으로** `ZK_HOME=/home/sysadmin/zookeeper` 같은 **고정 심링크**로 바꾸면 이후 업그레이드가 훨씬 단순해집니다.

---

## 2) 새 버전 설치(모든 노드 공통 준비)

```bash
# (각 ZK 노드에서 sysadmin로)
cd /home/sysadmin

# 1) 아카이브 배치 후 압축 해제
tar -xf apache-zookeeper-3.9.5-bin.tar.gz

# 2) 버전 심링크(권장) — 앞으로는 이 링크만 바꾸면 됨
ln -sfn apache-zookeeper-3.9.5-bin zookeeper
# (참고) 기존에 3.9.4로 링크가 있었다면 위 명령이 그것을 3.9.5로 바꿉니다.

# 3) 설정/스크립트 경로 확인
ls -l /home/sysadmin/zookeeper          # → apache-zookeeper-3.9.5-bin 로 가리켜야 함
```

### (선택) systemd 유닛 영구 개선

이전에 유닛이 버전 고정이었다면 **한 번만** 다음처럼 바꿔 주세요.

`~/.config/systemd/user/zookeeper@.service` 의 `Environment` 라인:

```ini
- Environment=ZK_HOME=/home/sysadmin/zookeeper-3.9.4
+ Environment=ZK_HOME=/home/sysadmin/zookeeper
```

적용:

```bash
systemctl --user daemon-reload
```

> 이렇게 바꿔두면 다음부터는 **심링크만 전환**하고 롤링 재시작하면 됩니다.

---

## 3) 롤링 업그레이드 절차(과반수 유지)

> 예시 순서: **zk2 → zk3 → zk1** (리더를 마지막에 바꾸는 습관을 권장)

### 3.1 zk2 업그레이드

```bash
# 상태 확인 (3.9.4 구동 중)
echo ruok | nc zk2 2181 ; echo
echo srvr | nc zk2 2181 | head -n 20

# 정지
systemctl --user stop zookeeper@zk2

# (유닛이 ZK_HOME=.../zookeeper 로 잡혀 있다면 심링크만 이미 3.9.5를 가리키므로 추가 조치 불필요)
# 만약 유닛에 버전이 박혀 있다면, 위 2단계 '유닛 영구 개선'을 먼저 반영하세요.

# 시작 (3.9.5로 기동)
systemctl --user start zookeeper@zk2

# 검증
echo ruok | nc zk2 2181 ; echo
echo srvr | nc zk2 2181 | grep -E 'Zookeeper version|Mode'
echo mntr | nc zk2 2181 | egrep 'zk_version|zk_server_state|zk_num_alive_connections'
```

### 3.2 zk3 업그레이드

위와 동일 절차로 `zookeeper@zk3` **stop → start → 검증**.

### 3.3 zk1 업그레이드

마지막으로 `zookeeper@zk1` **stop → start → 검증**.

> 모든 단계에서 **다른 두 노드가 정상**인지 항상 확인하여 **과반수(2/3)**가 유지되도록 하세요.

---

## 4) 클러스터 전체 검증

```bash
# 각 노드 버전/모드 요약
for host in zk1 zk2 zk3; do
  echo -n "$host: "
  echo srvr | nc $host 2181 | egrep 'Zookeeper version|Mode'
done

# 클라이언트 연결/세션/워치 등 핵심 지표(요약)
for host in zk1 zk2 zk3; do
  echo "== $host =="
  echo mntr | nc $host 2181 | egrep 'zk_server_state|zk_num_alive_connections|zk_outstanding_requests|zk_watch_count'
done
```

Solr 측도 간단 체크(예시):

```bash
# Solr 노드 한 곳에서 ZK 연결 정상/컬러 상태 점검
curl -s "http://nodeA:8983/solr/admin/collections?action=CLUSTERSTATUS&wt=json" | jq '.cluster.live_nodes|length'
```

---

## 5) 문제 발생 시 롤백

* 심링크 전략을 썼다면 **즉시 되돌리기** 가능:

  ```bash
  # 문제가 된 ZK 노드에서
  systemctl --user stop zookeeper@zkN
  ln -sfn apache-zookeeper-3.9.4-bin zookeeper
  systemctl --user start zookeeper@zkN
  ```
* 유닛이 버전 고정이면 일시적으로 `Environment=ZK_HOME=/home/sysadmin/zookeeper-3.9.4`로 되돌린 뒤 `daemon-reload` 후 재시작.
* 롤백 후에도 과반수 유지/리더 선출 상태를 `srvr/mntr`로 확인하세요.

---

## 6) 주의 & 권장값 재점검

* **데이터 호환성:** 3.9.x **마이너 업그레이드 간** 스냅샷/로그 포맷 변경 없음(일반적으로 롤링 안전).
* **4lw 보안:** 운영망에서 4lw는 방화벽/ACL로 제한하고, 필요한 명령만 화이트리스트(`4lw.commands.whitelist`)에 남겨두세요.
* **autopurge:** `autopurge.purgeInterval=12`, `autopurge.snapRetainCount=10` 유지/재확인.
* **파일디스크립터:** `LimitNOFILE=1048576`(systemd) 또는 ulimit 적용 확인.
* **시간 동기화:** 리더 선출 불안정 시 NTP/Chrony 재점검.
* **메트릭 포트:** Prometheus provider 사용 시 포트(예: 7000) 열려 있는지 확인.

---

## 7) 부록 — 수동 스크립트 예시(3노드 일괄)

```bash
# 순서: zk2 -> zk3 -> zk1
NODES=(zk2 zk3 zk1)

for n in "${NODES[@]}"; do
  echo ">>> upgrading $n to 3.9.5"
  systemctl --user stop "zookeeper@${n}"
  # 심링크 전환(이미 전환돼 있으면 생략 가능)
  ln -sfn /home/sysadmin/apache-zookeeper-3.9.5-bin /home/sysadmin/zookeeper
  systemctl --user start "zookeeper@${n}"

  # 간단 헬스체크
  echo -n "$n ruok: "; echo ruok | nc $n 2181 ; echo
  echo "---- srvr ----"; echo srvr | nc $n 2181 | egrep 'Zookeeper version|Mode'
  echo "---- mntr ----"; echo mntr | nc $n 2181 | egrep 'zk_server_state|zk_num_alive_connections'
done
```

---

### 결론

이 문서는 `/home/sysadmin` 트리에서 **심링크 전환 + 노드별 재시작**으로 **ZooKeeper 3.9.4 → 3.9.5**를 **무중단에 가깝게** 업그레이드하는 절차를 제공합니다.   
과반수 유지 원칙만 지키면 SolrCloud 서비스는 지속되며, 문제 발생 시 **심링크/유닛 되돌리기**로 신속히 롤백할 수 있습니다.
