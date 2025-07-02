# MySQL Status

## 1. `mysql_replication_delay-021230.sh`

### 📌 결과 해석

| 상황                            | 판단              |
| ----------------------------- | --------------- |
| `Seconds_Behind_Master = 150` | ✅ 정상            |
| `Seconds_Behind_Master = 250` | ❌ 오류, 지연 초과     |
| `Log_Position_Diff = 5MB`     | ✅ 정상            |
| `Log_Position_Diff = 25MB`    | ❌ 오류, 포지션 차이 초과 |

---


## 2. `mysql_replication_delay-021220.sh`

---

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

