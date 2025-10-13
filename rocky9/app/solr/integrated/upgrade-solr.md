# Apache Solr 9.9.1 롤링 업그레이드 가이드

**대상:** SolrCloud 멀티 인스턴스(포트별) 운영 환경 · **현재:** 9.9.0 · **목표:** 9.9.1 · **JDK:** OpenJDK 21 · **운영 계정:** `sysadmin` · **무중단(near-zero downtime) 롤링 전략**

---

## 0) 업그레이드 요약(체크리스트)

* [ ] **사전 점검:** 클러스터/리더 분포·복제상태 정상, 디스크 여유, 백업 준비
* [ ] **새 바이너리 배치:** `/opt/solr/solr-9.9.1` 전개 → `/opt/solr/current` 심볼릭 링크 전환 방식
* [ ] **롤링 재시작:** **비리더(NRT/TLOG) → 리더 순서**로 인스턴스별(포트별) 재시작
* [ ] **검증:** 컬렉션 상태, 쓰기/조회 캐너리, 에러로그 확인
* [ ] **정리:** 리더 재균형(선택), 모니터링 임계치 복원
* [ ] **롤백 플랜:** `/opt/solr/current`를 이전 버전으로 되돌려 같은 절차 반복

---

## 1) 전제(환경 상기)

* **배치 구조:** `/opt/solr-PORT/{bin,data,logs,run,env}` (사용자 소유)
* **공통 바이너리:** `/opt/solr/current/bin` 을 각 인스턴스 `bin`이 심링크로 사용
* **포트:** 8983–8990 (예시)
* **ZK 접속:** `ZK_HOST="zk1:2181,zk2:2181,zk3:2181/solr"`
* **GC:** 기본 G1GC, 필요 시 ZGC(21) 선택 가능

---

## 2) 사전 점검(필수)

```bash
# 클러스터 상태(복제/리더/라이브 노드)
curl -s "http://nodeA:8983/solr/admin/collections?action=CLUSTERSTATUS&wt=json" | jq '.cluster.summary,.cluster.live_nodes|length'

# 컬렉션·샤드 헬스(비정상 replica 없음 확인)
curl -s "http://nodeA:8983/solr/admin/collections?action=CLUSTERSTATUS&wt=json" \
| jq '.cluster.collections[]?.shards[]?.replicas[]? | select(.state!="active")'

# 디스크/FD/메모리 여유
df -h
ulimit -n
free -g
```

**백업(권장):** Repository API 증분 백업 또는 스냅샷 스토리지 백업을 **컬렉션 단위**로 실행하세요.
업그레이드 윈도우 동안 경고 알람 임계치를 일시 상향(선택).

---

## 3) 새 버전 배치

```bash
# 1) 배포(아카이브를 준비했다고 가정)
/bin/tar -C /opt/solr -xf solr-9.9.1.tgz
ln -sfn /opt/solr/solr-9.9.1 /opt/solr/current    # 심링크는 나중 '전환 시점'에 실행 권장

# 2) 호환성 확인(옵션)
grep -R "deprecated" /opt/solr/solr-9.9.1/server/solr-webapp/webapp/WEB-INF/lib | head
```

> **심링크 전환 타이밍:** 각 인스턴스를 **정지 → 심링크 전환 → 기동** 순으로 진행합니다(인스턴스별 순차 적용).

---

## 4) 롤링 업그레이드 절차(무중단 전략)

### 순서 계획

1. **비리더 replica**가 올라 있는 인스턴스(포트)부터 시작
2. 그 다음 **리더 replica**를 가진 인스턴스 처리
3. **서버 단위**가 아닌 **포트(인스턴스) 단위**로 순차 진행 → 영향 최소화

> 어느 포트가 리더인지 확인:

```bash
curl -s "http://nodeA:8983/solr/admin/collections?action=CLUSTERSTATUS&wt=json" \
| jq -r '.cluster.collections."<컬렉션>".shards | to_entries[] |
         .key as $s | .value.replicas | to_entries[] |
         select(.value.leader== "true") |
         "shard=\($s) leader=\(.key) node=\(.value.node_name)"'
```

### 인스턴스(포트)별 실행 예 (nodeA:8983 예시)

```bash
# 1) 중지
systemctl --user stop solr@8983     # 또는 /opt/solr-8983/stop.sh

# 2) 바이너리 심링크 전환(한 번만 해도 되지만, 안전하게 포트별 중지 직후 수행 권장)
ln -sfn /opt/solr/solr-9.9.1 /opt/solr/current

# 3) 기동
systemctl --user start solr@8983    # 또는 /opt/solr-8983/start.sh

# 4) 헬스 확인(해당 포트)
curl -s "http://nodeA:8983/solr/admin/info/system?wt=json" | jq '.lucene, .solr_home'
curl -s "http://nodeA:8983/solr/admin/metrics?group=jetty&wt=json" | jq '.[].metrics."solr.jetty.requests.active"'
```

### 각 인스턴스 적용 후 클러스터 확인

```bash
# 라이브 노드 및 비정상 replica 유무
curl -s "http://nodeA:8983/solr/admin/collections?action=CLUSTERSTATUS&wt=json" \
| jq '.cluster.live_nodes, (.cluster.collections[]?.shards[]?.replicas[]? | select(.state!="active"))'
```

> **Tip:** 특정 샤드에서 리더를 피하고 싶다면, 해당 샤드에서 리더가 아닌 레플리카가 배치된 포트부터 처리하세요. 마지막에 `REBALANCELEADERS`로 리더를 재분배할 수 있습니다.

---

## 5) 기능 검증(각 배치 구간마다)

### 캐너리 쓰기/조회

```bash
# 쓰기(weblog 예시)
curl -s "http://nodeA:8983/solr/weblog/update?commit=true" \
  -H 'Content-Type: application/json' \
  -d '[{"id":"upgrade_canary_'$(date +%s)'","msg_s":"hello-9.9.1"}]'

# 조회
curl -s "http://nodeA:8983/solr/weblog/select?q=id:upgrade_canary_*&wt=json" | jq '.response.numFound'
```

### 리더 재분배(선택)

```bash
curl -s "http://nodeA:8983/solr/admin/collections" --data 'action=REBALANCELEADERS&maxAtOnce=10&maxWaitSeconds=60'
```

---

## 6) 마이그레이션 포인트

* **설정 파일 유지:** 각 인스턴스의 `env`(HEAP/옵션/경로)는 그대로 사용.
* **JDK 21:** 기존 G1GC 플래그 호환. ZGC 사용 시 G1 관련 플래그 제거.
* **플러그인/핸들러:** 커스텀 플러그인은 9.9.1 호환 여부 확인(클래스 경로 충돌 주의).
* **Autoscaling 정책:** Solr 9.x는 구 정책 제거됨 → 노드 배치/리더 재분배는 API 기반으로 수행.

---

## 7) 문제 발생 시 롤백

1. 인스턴스(포트)별 즉시 복구

```bash
systemctl --user stop  solr@8983
ln -sfn /opt/solr/solr-9.9.0 /opt/solr/current
systemctl --user start solr@8983
```

2. 클러스터 확인 및 캐너리 테스트 재수행
3. 필요 시 리더 재분배로 부하 균형

---

## 8) 완료 후 정리

* **버전 확인(전 노드/포트):**

```bash
for p in 8983 8984 8985 8986 8987 8988 8989 8990; do
  curl -s "http://nodeA:${p}/solr/admin/info/system?wt=json" | jq -r '"port='"$p"': " + .lucene.SolrSpecificationVersion'
done
```

* **모니터링 임계치 복원**(GC, 지연, QPS, 5xx 등)
* **로그 회전 점검**: `/opt/solr-PORT/logs` 용량 체크 및 logrotate 정책 확인

---

## 9) 시간 계획(가이드)

* 인스턴스(포트) 1개당 **정지→기동→헬스체크 30~90초** 수준(환경/컬렉션 규모에 따라 차이)
* 8포트 × 1대 기준 **수 분 ~ 수십 분** 내에 롤링 완료 가능(대규모 컬렉션/세그먼트 병합 진행 중이면 증가)

---

## 10) 부록 — 수동(스크립트) 롤링 예시

```bash
# 업그레이드 대상 포트 배열(비리더 우선 순서로 구성해두면 더 안전)
PORTS=(8984 8985 8986 8987 8988 8989 8990 8983)

for P in "${PORTS[@]}"; do
  echo "[*] upgrade port $P"
  systemctl --user stop "solr@${P}" || /opt/solr-${P}/stop.sh || true
  ln -sfn /opt/solr/solr-9.9.1 /opt/solr/current
  systemctl --user start "solr@${P}" || /opt/solr-${P}/start.sh
  # 단순 헬스체크
  curl -sf "http://localhost:${P}/solr/admin/info/system?wt=json" >/dev/null
done
```

---

### 결론

이 문서는 **심볼릭 링크 전환 + 포트별 롤링 재시작**으로 **Solr 9.9.0 → 9.9.1**을 **무중단에 가깝게** 업그레이드하는 실무 절차를 제공합니다.  
운영 중 문제 시 **포트 단위로 즉시 롤백**이 가능하며, 리더/레플리카 순서를 지키고 캐너리로 검증하면 위험을 최소화할 수 있습니다.
