👍 말씀하신 **“# C. 리커버리 완료 대기 (개선: ping OK 연속 시 탈출)”** 블록이 제가 고쳐드린 핵심 부분입니다.
원래는 CLUSTERSTATUS 응답에서 `"state":"recovering|down|..."` 같은 문자열이 없어질 때까지 무한 대기 → “비-Active replica 1개 남음” 로그가 계속 찍혔습니다.

지금은 **코어 ping 응답을 추가 확인**해서, 실제 서비스가 정상이라면 더 이상 무한 대기하지 않고 경고 한 번 찍고 빠져나오도록 개선했습니다.

---

## 코드 흐름 설명

### 1) 변수 초기화

```bash
MAX_WAIT_SEC=$((20*60))   # 최대 20분 대기
INTERVAL=10               # 10초마다 체크
elapsed=0
consecutive_ping_ok=0      # 연속 Ping OK 횟수
PING_OK_TARGET=3           # Ping OK 3번 연속이면 정상으로 간주
```

* 20분 넘게 기다리면 강제 탈출.
* Ping OK가 3번 연속 나오면 “서비스 정상”으로 보고 루프 탈출.

---

### 2) 코어 ping 체크

```bash
all_ok=1
for CORE in $CORE_LIST; do
  code=$(curl ... "$CORE/admin/ping")
  if [ "$code" != "200" ]; then
    all_ok=0
    break
  fi
done
```

* 각 Core에 `/admin/ping` API 호출.
* 모두 `200`이면 `all_ok=1` → `consecutive_ping_ok` +1
* 하나라도 실패하면 카운터 0으로 초기화.

---

### 3) CLUSTERSTATUS 확인

```bash
json=$(curl ...)
not_active_lines=$(echo "$json" | grep -oE '"state":"(recovering|down|recovery_failed|inactive)"' || true)
count_not_active=$(printf "%s\n" "$not_active_lines" | wc -l | tr -d ' ')
```

* Zookeeper에 보고된 replica 상태 중 비-Active 개수를 셈.
* 정상이라면 0.

---

### 4) 종료 조건

1. **정상**:

   ```bash
   if [ "$count_not_active" -eq 0 ]; then
     echo "✅ 모든 replica ACTIVE"
     break
   fi
   ```

   → CLUSTERSTATUS 상에서도 모두 Active라면 즉시 탈출.

2. **Ping 기준으로 강제 탈출**:

   ```bash
   if [ "$consecutive_ping_ok" -ge "$PING_OK_TARGET" ]; then
     echo "⚠️ replica 비-Active가 남았지만 ping 연속 OK → 운영 가능으로 간주"
     break
   fi
   ```

   → CLUSTERSTATUS는 여전히 비-Active라고 해도,
   **실제 Core들이 3회 연속 ping OK**면 경고 로그 남기고 탈출.
   (= “유령 replica” 같은 고착 상황을 무한 반복하지 않음)

3. **시간 초과**:
   20분을 넘기면 `⏱️ 최대 대기 초과` 출력하고 탈출.

---

### 5) 로그 보강

```bash
echo "$json" ... | grep -E '"state":"(recovering|down|...)"'
```

* Ping OK로 탈출한 경우, 어떤 replica가 ZK에 “recovering/down”으로 남았는지 **suspect 목록**을 로그에 찍어줍니다.
* 운영엔 영향 없지만 관리자가 확인할 수 있게 힌트 제공.

---

## 요약

* **원래:** CLUSTERSTATUS가 100% Active 될 때까지 무조건 대기.
* **지금:**

  * CLUSTERSTATUS Active → 정상 종료
  * 아니어도 ping 연속 OK면 경고 후 종료 (무한 반복 방지)
  * 그래도 안 되면 20분 뒤 강제 종료

즉, **운영 서비스 관점에서는 Ping 결과를 우선시**해서,
ZK에만 남아 있는 “유령/죽은 replica” 때문에 루프가 끝나지 않는 문제를 해결한 것입니다.

---

👉 원하시면 `PING_OK_TARGET`을 3에서 2나 5로 조정해서 **안전성 vs. 속도** 균형을 바꿀 수 있습니다.

혹시 제가 이 부분을 **주석 달아 가며 리팩터링**해 드리면 더 이해하기 쉬우실까요?
