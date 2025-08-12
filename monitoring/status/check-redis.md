이 Bash 스크립트는 **Redis Cluster의 마스터/슬레이브 노드 상태를 점검**하는 자동화 도구입니다. 목적은 **각 노드의 역할(master/slave) 확인**, **비정상 상태 탐지**, 그리고 **이상 발생 시 메일 경고 전송**입니다.

---

## ✅ 전체 동작 요약

| 항목    | 설명                                                |
| ----- | ------------------------------------------------- |
| 점검 대상 | Redis 클러스터 (포트 `6381`)의 마스터/슬레이브 노드               |
| 점검 방식 | 각 노드에 대해 `redis-cli CLUSTER NODES` 결과를 파싱하여 역할 확인 |
| 판단 기준 | 실제 역할이 기대 역할과 다르거나 응답이 없으면 `CRITICAL`             |
| 결과 처리 | 장애 발견 시 `syslog` 기록 + 메일 발송(`joo@qubitsec.com`)   |
| 정상 상태 | 모든 노드가 정상이면 OK 출력 후 종료 코드 `0`                     |

---

## 🔍 주요 코드 블록 설명

### 1. 환경 및 대상 노드 설정

```bash
REDIS_PORT=6381
REDIS_MASTERS=(10.100.21.140 ... )
REDIS_SLAVES=(10.100.21.150 ... )
```

* Redis 노드들이 포트 `6381`에서 운영된다는 전제
* 각 노드를 마스터/슬레이브로 명확히 구분하여 점검

---

### 2. 핵심 함수: `check_redis_node()`

이 함수는 개별 노드가 정상인지 확인합니다.

```bash
redis_info=$(redis-cli -h "$node" -p "$REDIS_PORT" CLUSTER NODES)
```

* Redis 노드의 클러스터 정보를 조회
* `redis_info`가 비어 있거나 오류면 `접속 불가`

```bash
role_type=$(echo "$redis_info" | awk '{print $3}' | cut -d',' -f1)
```

* 현재 노드의 역할 추출 (`master`, `slave`, 또는 `myself,master` 형식 처리)

```bash
if [ "$expected_role" != "$role_type" ]; then
  ...
```

* 기대 역할(`master` 또는 `slave`)과 실제 역할이 다르면 오류 처리

---

### 3. 상태 누적 처리

```bash
ERROR_MESSAGES+=("$msg")
STATUS_OK=false
```

* 하나라도 실패하면 전체 상태를 `false`로 설정
* 오류 메시지는 배열에 누적 → 이후 메일 본문에 사용

---

### 4. 점검 실행

```bash
for node in "${REDIS_MASTERS[@]}"; do
    check_redis_node "$node" "master" || STATUS_OK=false
done

for node in "${REDIS_SLAVES[@]}"; do
    check_redis_node "$node" "slave" || STATUS_OK=false
done
```

* 모든 마스터/슬레이브 노드를 순회하면서 상태 점검
* 실패 시 `STATUS_OK=false`로 설정됨

---

### 5. 결과 출력 및 알림 처리

```bash
if $STATUS_OK; then
  echo "... OK ..."
  exit 0
else
  echo "... | mail ... "
  exit 2
fi
```

* 모든 점검이 정상일 경우 `Status=OK` 출력 후 종료
* 하나라도 실패하면 메일 발송 및 `exit 2` 반환

---

## 📌 장애 판단 기준 요약

| 항목                         | 판단 조건                                |
| -------------------------- | ------------------------------------ |
| Redis 응답 없음                | ❌ 오류 (`unreachable or unresponsive`) |
| 역할 불일치 (`master`, `slave`) | ❌ 오류 (`expected vs actual`)          |

---

## 📤 메일 알림 예시 (장애 발생 시)

```
Subject: [ALERT] Redis 장애 감지

[ALERT] Redis 장애 감지
실행 시간: 2025-07-02 10:00:00

장애 상태:
- CRITICAL: Node 10.100.21.144:6381 is expected to be master but found slave
- CRITICAL: Node 10.100.21.154:6381 is unreachable or unresponsive
```

---

## ✅ 정상 출력 예시

```
2025-07-02 10:00:00 | Status=OK, Redis cluster is healthy on port 6381
```

---

## 🛠 개선 아이디어 (선택 사항)

| 항목                 | 개선 제안                                                                                         |
| ------------------ | --------------------------------------------------------------------------------------------- |
| IP 누락 방지           | `redis-cli`에서 노드 IP가 다르게 표기되는 경우 `grep $node`는 실패할 수 있음 → `grep myself` 또는 `awk`로 ID 기반 처리 추천 |
| HTML 또는 CSV 리포트 출력 | 메일 본문을 보기 좋게 포맷팅                                                                              |
| 장애시 재시도 로직 추가      | 일시적 장애를 구분하려면 `ping` or 재시도 로직 고려                                                             |

---
