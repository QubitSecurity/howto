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
