# MySQL Status

## 1. `mysql_replication_delay-021230.sh`

### ✅ 스크립트의 판별 로직 기준 요약

| 항목                                      | 조건 설명                                                   |
| --------------------------------------- | ------------------------------------------------------- |
| `Seconds_Behind_Master`                 | 200초 이상이면 ❌ 오류로 판단                                      |
| `Slave_IO_Running`, `Slave_SQL_Running` | 둘 중 하나라도 `Yes`가 아니면 ❌ 오류                                |
| `Log_File` 불일치                          | Master/Slave의 `File` 값 다르면 ❌ 오류                         |
| `Log_Position_Diff` 차이                  | Slave가 Master보다 느리고 차이 > 20MB (20,000,000 bytes)이면 ❌ 오류 |

---

### 📌 결과 해석 예시 (스크립트 기준)

| 상황                                                  | 판단              |
| --------------------------------------------------- | --------------- |
| `Seconds_Behind_Master = 150`                       | ✅ 정상            |
| `Seconds_Behind_Master = 250`                       | ❌ 오류, 지연 초과     |
| `Slave_IO_Running = No` 또는 `Slave_SQL_Running = No` | ❌ 오류, 복제 중단     |
| `Log_File: mysql-bin.002732 / mysql-bin.002733`     | ❌ 오류, 로그 파일 불일치 |
| `Log_Position_Diff = 5MB`                           | ✅ 정상            |
| `Log_Position_Diff = 25MB`                          | ❌ 오류, 포지션 차이 초과 |

---

### 💡 참고

* 스크립트 내에서 로그 포지션 차이는 다음 조건으로 계산됩니다:

```bash
pos_diff=$((MASTER_LOG_POS - slave_pos))
[ $pos_diff -lt 0 ] && pos_diff=$(( -1 * pos_diff ))
if [ "$pos_diff" -ge "$MAX_ALLOWED_LOG_POSITION_DIFF" ]; then
    status="ERROR"
```

* `Seconds_Behind_Master`는 다음처럼 비교합니다:

```bash
if [ "$secs_behind" != "NULL" ] && [ "$secs_behind" -ge "$MAX_ALLOWED_DELAY" ]; then
    status="ERROR"
fi
```

---

### 📤 메일 알림

오류가 하나라도 발생하면 다음과 같이 메일로 발송됩니다:

* 제목: `[ALERT] MySQL 복제 이상 (호스트이름)`
* 내용: 모든 오류 메시지 목록

---


## 2. `mysql_replication_delay-021220.sh`

### ✅ **판별 로직 기준 정리**

| 항목                      | 기준 조건                                            |
| ----------------------- | ------------------------------------------------ |
| `Seconds_Behind_Master` | 30초 이상이면 **CRITICAL**                            |
| `IO / SQL 상태`           | 둘 중 하나라도 `Yes`가 아니면 **CRITICAL**                 |
| `로그 파일명 불일치`            | 마스터와 슬레이브 `File` 다르면 **CRITICAL**                |
| `로그 포지션 차이`             | 슬레이브가 마스터보다 느리며, `Δ > 1000 Bytes`이면 **CRITICAL** |

> ✅ `abs()` 함수로 로그 포지션 차이(Δ)를 계산하고 1000 바이트 초과 시 오류 처리합니다.

---

### 📌 결과 해석 예시 (현재 스크립트 기준)

| 상황                                                  | 판단              |
| --------------------------------------------------- | --------------- |
| `Seconds_Behind_Master = 20`                        | ✅ 정상            |
| `Seconds_Behind_Master = 150`                       | ❌ 오류, 지연 초과     |
| `Slave_IO_Running = No` 또는 `Slave_SQL_Running = No` | ❌ 오류, 복제 중단     |
| `Log_File: mysql-bin.002732 / mysql-bin.002733`     | ❌ 오류, 로그 파일 불일치 |
| `Log_Position_Diff = 900`                           | ✅ 정상            |
| `Log_Position_Diff = 1500`                          | ❌ 오류, 포지션 차이 초과 |

---

### 📝 보완 제안 (옵션)

현재 기준은 **비교적 민감한 설정**입니다. 대용량 시스템에서는 다음과 같이 조정 가능합니다:

| 항목                      | 기존 값  | 추천 완화값               |
| ----------------------- | ----- | -------------------- |
| `Seconds_Behind_Master` | 30초   | **200초**             |
| `POS_TOLERANCE`         | 1000B | **20000000B (20MB)** |

이 경우 다음과 같은 해석이 됩니다:

---

### 📌 결과 해석 예시 (완화 기준 적용 시)

| 상황                            | 판단              |
| ----------------------------- | --------------- |
| `Seconds_Behind_Master = 150` | ✅ 정상            |
| `Seconds_Behind_Master = 250` | ❌ 오류, 지연 초과     |
| `Log_Position_Diff = 5MB`     | ✅ 정상            |
| `Log_Position_Diff = 25MB`    | ❌ 오류, 포지션 차이 초과 |

---

### 📎 설정 변경 방법

스크립트 상단에서 다음처럼 수정하면 완화 기준 적용이 가능합니다:

```bash
POS_TOLERANCE=20000000  # 20MB
```

```bash
{ [ "$secs_behind" != "NULL" ] && [ "$secs_behind" -ge 200 ]; }
```

---


## 3. `mysql_replication_delay-021060.sh`

### ✅ 스크립트 판단 로직 요약

| 항목                                      | 조건 및 기준                  |
| --------------------------------------- | ------------------------ |
| `Seconds_Behind_Master`                 | 30초 이상이면 ❌ 오류            |
| `Slave_IO_Running`, `Slave_SQL_Running` | 둘 중 하나라도 `Yes`가 아니면 ❌ 오류 |
| `Log_File` 불일치                          | 마스터와 슬레이브 파일명이 다르면 ❌ 오류  |
| `Log_Position_Diff` 차이                  | `Δ > 1000 바이트`이면 ❌ 오류    |

> 💡 포지션 차이 계산 시 `abs()` 함수를 사용하여 절대값으로 비교

---

### 📌 결과 해석 예시 (현재 스크립트 기준)

| 상황                                                  | 판단              |
| --------------------------------------------------- | --------------- |
| `Seconds_Behind_Master = 10`                        | ✅ 정상            |
| `Seconds_Behind_Master = 45`                        | ❌ 오류, 지연 초과     |
| `Slave_IO_Running = No` 또는 `Slave_SQL_Running = No` | ❌ 오류, 복제 중단     |
| `Log_File: mysql-bin.002700 / mysql-bin.002701`     | ❌ 오류, 로그 파일 불일치 |
| `Log_Position_Diff = 800B`                          | ✅ 정상            |
| `Log_Position_Diff = 1,500B`                        | ❌ 오류, 포지션 차이 초과 |

---

### ⚠️ 보완 및 개선 방향 제안

현재 기준은 **비교적 민감한 설정**입니다. 대용량 복제 환경에서는 다음과 같은 조정이 권장될 수 있습니다:

| 항목                      | 현재 값     | 개선 제안             |
| ----------------------- | -------- | ----------------- |
| `Seconds_Behind_Master` | 30초      | 200초              |
| `POS_TOLERANCE`         | 1000 바이트 | 20MB (`20000000`) |

이 기준은 대량 로그가 발생하는 시스템에서 **불필요한 경고를 줄이고**, **실제 오류만 탐지**하는 데 도움이 됩니다.

---

### 📤 메일 전송 구성

오류 발생 시 자동으로 다음과 같이 메일이 발송됩니다:

* 제목: `[ALERT] MySQL 복제 상태 이상 (서버명)`
* 본문: 각 슬레이브별 오류 상세 메시지

---

