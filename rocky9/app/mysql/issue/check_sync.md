MySQL에서 **마스터-리플리카(Master-Replica)** 구조에서 동기화 상태를 확인하는 방법은 여러 가지가 있습니다. **동기화 상태 확인**은 주로 **슬레이브(리플리카)가 마스터와 제대로 동기화되고 있는지**를 체크하는 과정입니다. 여기서는 주요 방법들을 상세히 설명드립니다.

---

### ✅ 1. **마스터 서버에서 확인 (SHOW MASTER STATUS)**

마스터 서버에서 현재 \*\*이벤트 로그(바이너리 로그)\*\*와 관련된 상태를 확인하여, 마스터 서버가 정상적으로 바이너리 로그를 생성하고 있는지 확인합니다.

```sql
SHOW BINARY LOG STATUS;
```

#### 출력 예시:

| File             | Position | Binlog\_Do\_DB | Binlog\_Ignore\_DB | Executed\_Gtid\_Set |
| ---------------- | -------- | -------------- | ------------------ | ------------------- |
| mysql-bin.000001 | 107      |                |                    |                     |

* **File**: 마스터 서버의 바이너리 로그 파일 이름.
* **Position**: 해당 바이너리 로그 파일 내의 마지막 처리된 위치.
* **Executed\_Gtid\_Set**: 만약 GTID 복제를 사용하는 경우, 실행된 GTID 세트가 표시됩니다.

---

### ✅ 2. **슬레이브(리플리카) 서버에서 확인 (SHOW SLAVE STATUS)**

슬레이브 서버에서 **동기화 상태를 확인**하는 가장 중요한 명령어입니다. `SHOW SLAVE STATUS` 명령어를 통해 슬레이브의 동기화 상태를 알 수 있습니다.

```sql
SHOW REPLICA STATUS\G
```

#### 출력 예시:

```plaintext
Replica_IO_State: Waiting for master to send event
Source_Host: 192.168.1.1
Source_User: repl_user
Source_Port: 3306
Connect_Retry: 60
Source_Log_File: mysql-bin.000001
Read_Source_Log_Pos: 107
Relay_Log_File: mysqld-relay-bin.000001
Relay_Log_Pos: 107
Relay_Source_Log_File: mysql-bin.000001
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
...
```

* **Slave\_IO\_Running**: **YES**이면 슬레이브의 I/O 스레드가 마스터와 연결되어 정상적으로 로그를 수신 중임을 의미합니다.
* **Slave\_SQL\_Running**: **YES**이면 슬레이브의 SQL 스레드가 정상적으로 로그를 처리하고 있다는 의미입니다.
* **Master\_Log\_File**: 마스터 서버에서 사용 중인 현재 바이너리 로그 파일 이름.
* **Read\_Source\_Log\_Pos**: 슬레이브가 현재 마스터의 바이너리 로그 파일에서 읽고 있는 위치.
* **Relay\_Source\_Log\_File**: 슬레이브의 리레이 로그 파일과 관련된 마스터의 바이너리 로그 파일.
* **Relay\_Log\_Pos**: 슬레이브가 현재 리레이 로그에서 처리하고 있는 위치.

### 확인 사항:

* **Slave\_IO\_Running: Yes**와 **Slave\_SQL\_Running: Yes**가 모두 **YES**라면 동기화가 정상입니다.
* 만약 **Slave\_IO\_Running** 또는 **Slave\_SQL\_Running**이 **No**라면 동기화에 문제가 있는 것입니다. 이 경우 추가적인 오류 메시지가 나올 수 있으니, **Last\_Error** 필드를 확인해야 합니다.

---

### ✅ 3. **슬레이브의 동기화 지연 확인 (Seconds\_Behind\_Master)**

슬레이브의 동기화 지연을 확인하려면 **Seconds\_Behind\_Master** 필드를 확인할 수 있습니다. 이 값은 **슬레이브가 마스터로부터 몇 초만큼 지연되고 있는지**를 나타냅니다.

```sql
SHOW REPLICA STATUS\G
```

#### 출력 예시:

```plaintext
Seconds_Behind_Master: 0
```

* **0**이면 슬레이브가 마스터와 동기화가 정상적으로 이루어지고 있다는 의미입니다.
* **음수 또는 NULL**이면 동기화에 문제가 있을 수 있습니다. 이런 경우에는 `Last_Error`와 같은 오류 메시지를 확인하여 원인을 파악할 수 있습니다.

---

### ✅ 4. **GTID 기반 복제 확인 (SHOW GLOBAL STATUS)**

GTID(전역 트랜잭션 ID) 복제를 사용하고 있다면, GTID 기반으로 동기화 상태를 확인할 수 있습니다. 마스터와 슬레이브에서 각각 GTID 정보를 확인합니다.

#### 마스터에서 확인:

```sql
SHOW BINARY LOG STATUS;
```

#### 슬레이브에서 확인:

```sql
SHOW REPLICA STATUS\G
```

* **Executed\_Gtid\_Set**: 슬레이브가 실행한 GTID 세트를 확인하고, 마스터에서 생성된 GTID와 비교하여 동기화 상태를 확인합니다.

---

### ✅ 5. **네트워크 및 시스템 로그 확인**

* **슬레이브 서버의 에러 로그**에서 복제 관련 문제를 찾을 수 있습니다. `/var/log/mysql/error.log` 또는 `/var/log/mysqld.log` 파일에서 복제 오류가 발생한 경우 관련 메시지를 확인하세요.
* 복제 지연이나 I/O 오류 등은 이 로그에 기록됩니다.

---

### ✅ 6. **복제 지연 문제 해결**

복제 지연이나 동기화 문제를 해결하기 위한 방법들은 다음과 같습니다:

1. **슬레이브 서버의 `IO` 또는 `SQL` 스레드가 멈춘 경우:**

   * `STOP REPLICA;` 후 `START REPLICA;`로 복제 스레드를 재시작합니다.

   ```sql
   STOP REPLICA;
   START REPLICA;
   ```

2. **슬레이브의 바이너리 로그를 마스터와 동기화:**

   * 슬레이브가 마스터와 동기화되지 않은 경우, `RESET REPLICA` 명령을 사용하여 복제를 재설정하고, 새로운 복제를 설정할 수 있습니다.

   ```sql
   RESET REPLICA ALL;
   ```

3. **`Seconds_Behind_Master` 지연이 너무 큰 경우:**

   * 네트워크 성능 문제나 슬레이브의 처리 성능 부족이 원인일 수 있습니다. 이 경우, 슬레이브의 리소스를 조정하거나 네트워크 성능을 개선해야 할 수 있습니다.

---

## 결론

* **동기화 확인**: `SHOW REPLICA STATUS`와 `SHOW BINARY LOG STATUS`를 통해 슬레이브와 마스터의 동기화 상태를 확인할 수 있습니다.
* **슬레이브 지연**: `Seconds_Behind_Master` 필드를 확인하여 지연을 확인하고, 지연이 너무 길면 성능 문제를 해결할 필요가 있습니다.
* **복제 오류**: 에러 로그나 `Last_Error` 필드를 통해 복제 문제를 진단하고 해결할 수 있습니다.

동기화 상태를 정확하게 모니터링하려면, **슬레이브와 마스터의 상태를 주기적으로 확인**하고, **자동화된 모니터링 시스템**을 사용하는 것이 좋습니다.
