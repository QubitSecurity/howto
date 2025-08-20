요청하신 대로 **최신 개선 내용( `/select` 헬스체크 + plateau 감지 )을** 반영해 설명을 업데이트했습니다. 핵심은 *ping만* 보지 않고, **쿼리 가능 상태(`/select?q=*:*&rows=0`)를 1순위**로 확인하며, **비-Active 개수가 오랫동안 변동 없으면(plateau) 유령 replica로 간주**해 경고 후 탈출한다는 점입니다.

---

# C. 리커버리 완료 대기 (최신 개선 요약)

* **우선순위 헬스체크 변경**:

  * 1순위: `GET /solr/<CORE>/select?q=*:*&rows=0` (실제 쿼리 가능 여부)
  * 2순위(보조): `GET /solr/<CORE>/admin/ping` (ping 미구성/비표준 환경 대비)
* **연속 정상 응답 시 탈출**: 모든 코어가 **연속 N회(기본 3회)** 정상 응답이면, ZK의 비-Active 표기에 상관없이 **경고 1회** 남기고 루프 종료
* **plateau(정체) 감지 추가**: 비-Active 개수가 **여러 번 연속 동일**(기본 12회 × 10초 = 약 2분)하면, **유령 replica** 가능성으로 보고 **경고 후 종료**
* **최대 대기 한도**: 기본 20분

---

## 코드 흐름 (변경점 반영)

### 1) 변수 초기화

```bash
MAX_WAIT_SEC=$((20*60))   # 최대 20분 대기
INTERVAL=10               # 10초 주기
elapsed=0

consecutive_ok=0          # 연속 정상 응답 횟수 (select 또는 ping)
OK_TARGET=3               # 연속 3회면 운영 가능으로 간주

last_count_not_active=""  # 직전 비-Active 개수 (plateau 감지용)
plateau_hits=0
STABLE_PLATEAU=12         # 같은 값이 12회 연속(≈2분) 유지되면 경고 후 탈출
```

* **변경**: `consecutive_ping_ok/PING_OK_TARGET` → `consecutive_ok/OK_TARGET` (이제 `/select`도 포함)
* **신규**: `last_count_not_active`, `plateau_hits`, `STABLE_PLATEAU` (plateau 감지)

---

### 2) 코어 헬스체크 (select → ping 순)

```bash
all_ok=1
for CORE in $CORE_LIST; do
  code_sel=$(curl -s -o /dev/null -w "%{http_code}" \
    "http://localhost:8983/solr/$CORE/select?q=*:*&rows=0" || echo 000)
  if [ "$code_sel" != "200" ]; then
    code_ping=$(curl -s -o /dev/null -w "%{http_code}" \
      "http://localhost:8983/solr/$CORE/admin/ping" || echo 000)
    if [ "$code_ping" != "200" ]; then
      all_ok=0
      break
    fi
  fi
done

consecutive_ok=$(( all_ok == 1 ? consecutive_ok+1 : 0 ))
```

* **변경 이유**: 어떤 환경에서는 `ping`이 미구성(404/503)인데도 코어는 쿼리 가능(200)합니다. `/select`를 1순위로 보면 **실서비스 정상 여부를 더 정확**히 판단합니다.

---

### 3) CLUSTERSTATUS로 비-Active 개수 파악

```bash
json=$(curl -s --max-time 5 "http://localhost:8983/solr/admin/collections?action=CLUSTERSTATUS&wt=json" || true)
not_active_lines=$(echo "$json" | grep -oE '"state":"(recovering|down|recovery_failed|inactive)"' || true)
count_not_active=$(printf "%s\n" "$not_active_lines" | wc -l | tr -d ' ')
```

* ZK 기준으로 **비-Active replica** 개수를 셉니다(메타 데이터 관점).

---

### 4) 종료 조건 (우선순위)

1. **ZK도 정상** → 즉시 종료

```bash
[ "$count_not_active" -eq 0 ] && echo "✅ 모든 replica ACTIVE" && break
```

2. **select/ping 연속 OK** → 경고 1회 후 종료

```bash
if [ "$consecutive_ok" -ge "$OK_TARGET" ]; then
  echo "⚠️ 비-Active ${count_not_active} 남았지만, /select 또는 ping 연속 OK → 운영 가능으로 간주"
  # 의심 레플리카 힌트 로그
  echo "$json" | tr -d '\n' | sed 's/{"replicas"/\n&/g' \
    | grep -E '"state":"(recovering|down|recovery_failed|inactive)"' -n \
    | head -n 20 | sed 's/^/  suspect: /'
  break
fi
```

3. **plateau(정체) 감지** → 경고 후 종료

```bash
if [ "$last_count_not_active" = "$count_not_active" ] && [ -n "$count_not_active" ]; then
  plateau_hits=$((plateau_hits+1))
else
  plateau_hits=0
  last_count_not_active="$count_not_active"
fi

if [ "$plateau_hits" -ge "$STABLE_PLATEAU" ]; then
  echo "⚠️ 비-Active ${count_not_active}가 약 $((plateau_hits*INTERVAL))초 동안 정체 → 유령 replica 의심, 진행"
  break
fi
```

* **신규 로직**: 비-Active 개수가 **오래 고정**되어 있으면, 운영엔 영향 없는 **메타 고착(ghost)** 가능성이 높다고 판단.

4. **최대 대기 초과** → 종료

```bash
elapsed=$((elapsed+INTERVAL))
[ "$elapsed" -ge "$MAX_WAIT_SEC" ] && echo "⏱️ 최대 대기 초과" && break
```

---

### 5) 로그 보강

* 연속 OK/plateau로 탈출할 때, **의심 레플리카 일부를 로그로 덤프**해서 나중에 `DELETEREPLICA&onlyIfDown=true` 같은 정리를 하도록 힌트를 제공합니다.

---

## 최종 요약 (차이점 정리)

* **이전 개선**: ping 연속 OK면 탈출
* **이번 개선**:

  1. **`/select`(쿼리 응답) 1순위** + ping은 보조
  2. **plateau 감지**로 유령 replica 장기 고착 시 **경고 후 진행**
  3. 변수·이름·조건을 `/select` 기준으로 정리(`consecutive_ok/OK_TARGET`)

이렇게 바꿔서, **실제 검색/색인 서비스가 정상**이면 불필요한 대기를 끝내고, **ZK 메타만 비정상**인 상황을 **운영 무중단**으로 넘길 수 있게 했습니다.
