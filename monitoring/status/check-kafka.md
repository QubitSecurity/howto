이 스크립트는 **Kafka 클러스터 상태 점검**을 자동화하는 Bash 스크립트입니다. 주요 기능은 **Lag 감지**, **Offline 파티션**, **리더 없음 상태**를 점검하고, **이상이 있을 경우 메일로 알림을 전송**하는 것입니다.

---

## ✅ 전체 목적

* Kafka 클러스터의 특정 \*\*토픽(`sys`)과 컨슈머 그룹(`analysis-syslog`)\*\*을 대상으로

  * 지연(Lag) 발생 여부
  * Offline 파티션 존재 여부
  * 리더 없는 파티션 존재 여부
* 각 Kafka 브로커별로 순회하며 점검
* 이상 발생 시 syslog 기록 및 메일 발송 (`plura@qubitsec.com`)

---

## 🔍 주요 구성 요소 설명

### 1. **Kafka 브로커 목록**

```bash
KAFKA_BROKERS=( ".22.201:9092" ... )
```

* 실제 IP 주소의 일부가 생략된 상태이므로 실제 실행을 위해선 `10.100.22.xxx:9092`와 같이 수정해야 합니다.

---

### 2. **점검 대상**

```bash
TOPIC="sys"
CONSUMER_GROUP="analysis-syslog"
LAG_THRESHOLD=10000
```

* `sys` 토픽의 Lag이 10,000 이상이면 CRITICAL로 판단

---

### 3. **Lag, 파티션 상태 점검**

```bash
kafka-consumer-groups.sh --describe ...
kafka-topics.sh --describe ...
```

브로커마다 다음 항목 점검:

| 항목            | 기준                  | 명령어                        |
| ------------- | ------------------- | -------------------------- |
| Lag 값         | `$LAG_THRESHOLD` 이상 | `kafka-consumer-groups.sh` |
| Offline 파티션   | 존재 시                | `grep Offline`             |
| Leader 없는 파티션 | 존재 시                | `grep "Leader: -1"`        |

---

### 4. **CRITICAL 상태 처리**

각 항목별로 기준 초과 시:

```bash
logger -t "$LOG_TAG" -p local0.err "$msg"
echo "$CURRENT_TIME | $msg"
ERROR_MESSAGES+=("$msg")
STATUS_OK=false
```

* syslog 기록
* 화면 출력
* 메일 본문에 추가

---

### 5. **정상 상태 출력 및 종료**

```bash
if $STATUS_OK; then
  echo "... | Status=OK ..."
  exit 0
```

### 6. **이상 발생 시 메일 발송**

```bash
if ! $STATUS_OK; then
  ... | mail -s "[ALERT] Kafka 장애 감지 ..." plura@qubitsec.com
  exit 2
```

---

## 📌 장애 판단 기준 요약

| 항목          | 판단 조건             |
| ----------- | ----------------- |
| Lag         | Lag > 10,000      |
| Offline 파티션 | 하나라도 있으면 CRITICAL |
| 파티션에 리더 없음  | 하나라도 있으면 CRITICAL |

---

## 📨 메일 내용 예시 (오류 발생 시)

```
[ALERT] Kafka 장애 감지
실행 시간: 2025-07-02 10:30:00

장애 상태:
- CRITICAL: Topic=sys, Offline_Partitions=2 ...
- CRITICAL: Topic=sys, Lag exceeded threshold ...
```

---

## ✅ 실행 결과 요약 예시 (정상)

```
2025-07-02 10:30:00 | Status=OK, Topic=sys, Lag=0, Threshold=10000, Offline_Partitions=0, Partitions_without_Leader=0, Kafka_Brokers=8
```

---

## 🔧 개선 포인트 제안 (선택)

* `.22.xxx` → IP 완성 필요
* `current_lag`는 마지막 브로커 기준이므로 broker별 상세 출력이 필요하면 누적 방식 개선 필요
* 정상 상태도 메일로 보고하고 싶다면 `if $STATUS_OK; then ...` 블록에서 메일 발송 추가 가능

---
