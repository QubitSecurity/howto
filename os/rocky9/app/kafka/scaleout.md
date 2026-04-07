# How to scaleout


Kafka 클러스터 확장은 기존 Kafka 클러스터에 새로운 브로커를 추가하여 처리 용량, 내구성, 및 가용성을 향상시키는 작업입니다. Kafka 브로커를 확장하려면 다음 절차를 따르세요:

---

### **1. 신규 Kafka 브로커 설치**
#### **1.1 Kafka 설치**
- 새로운 물리적 또는 가상 머신에 Kafka를 설치합니다.
  - 기존 브로커와 동일한 Kafka 버전을 설치합니다.
  - Kafka 다운로드:
    ```bash
    wget https://downloads.apache.org/kafka/3.8.0/kafka_2.12-3.8.0.tgz
    tar -xzf kafka_2.12-3.8.0.tgz
    mv kafka_2.12-3.8.0 /opt/kafka
    ```

#### **1.2 클러스터 네트워크 구성**
- 모든 브로커 간 통신이 가능하도록 방화벽 및 네트워크 설정을 확인합니다.
- 새 브로커 머신에서 기존 ZooKeeper와 통신 가능한지 확인합니다.
  ```bash
  telnet <zookeeper-host> 2181
  ```

---

### **2. 신규 브로커 설정**
#### **2.1 `server.properties` 수정**
새 브로커의 설정 파일 `/opt/kafka/config/server.properties`를 수정합니다:
1. **`broker.id` 설정**
   - 클러스터 내에서 고유한 숫자를 지정합니다.
     ```properties
     broker.id=3  # 기존 브로커가 0, 1, 2라면 3으로 설정
     ```

2. **클러스터 정보 설정**
   - 기존 클러스터의 ZooKeeper 정보를 설정합니다:
     ```properties
     zookeeper.connect=<zookeeper-host1>:2181,<zookeeper-host2>:2181,<zookeeper-host3>:2181
     ```
     (Kafka 3.4.0 이상에서 ZooKeeper가 아닌 KRaft를 사용하는 경우, `controller.quorum.voters`를 설정합니다.)

3. **로그 디렉터리 설정**
   - 브로커가 데이터를 저장할 디렉터리 설정:
     ```properties
     log.dirs=/var/lib/kafka/data
     ```

4. **네트워크 설정**
   - 브로커가 바인딩할 IP와 포트를 설정합니다:
     ```properties
     listeners=PLAINTEXT://<브로커 IP>:9092
     advertised.listeners=PLAINTEXT://<브로커 IP>:9092
     ```

#### **2.2 JMX 및 메모리 설정**
- JVM 힙 메모리 크기 설정 (`KAFKA_HEAP_OPTS`):
  ```bash
  export KAFKA_HEAP_OPTS="-Xmx2G -Xms2G"
  ```
- JMX를 통해 모니터링을 활성화하려면 환경 변수 설정:
  ```bash
  export KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=9999"
  ```

---

### **3. 새 브로커 시작**
Kafka를 실행합니다:
```bash
/opt/kafka/bin/kafka-server-start.sh -daemon /opt/kafka/config/server.properties
```

#### **확인**
- 브로커가 ZooKeeper에 등록되었는지 확인:
  ```bash
  /opt/kafka/bin/zookeeper-shell.sh <zookeeper-host>:2181 ls /brokers/ids
  ```
  새로운 브로커 ID가 표시되면 성공적으로 등록된 것입니다.

---

### **4. 데이터 리밸런싱**
새로운 브로커가 추가되면, 기존 토픽의 파티션을 새 브로커로 리밸런싱해야 합니다.

#### **4.1 토픽 리밸런싱 확인**
- 현재 파티션 분포 확인:
  ```bash
  /opt/kafka/bin/kafka-topics.sh --describe --bootstrap-server <existing-broker>:9092 --topic <topic-name>
  ```

#### **4.2 토픽 리어사인 계획 생성**
- 리어사인 계획을 생성합니다:
  ```bash
  /opt/kafka/bin/kafka-reassign-partitions.sh --zookeeper <zookeeper-host>:2181 --generate --topics-to-move-json-file topics-to-move.json --broker-list <broker-ids>
  ```
  **`topics-to-move.json` 예시**:
  ```json
  {
    "topics": [
      {"topic": "test-topic"}
    ],
    "version": 1
  }
  ```

#### **4.3 리어사인 적용**
- 생성된 계획을 기반으로 리어사인을 실행합니다:
  ```bash
  /opt/kafka/bin/kafka-reassign-partitions.sh --zookeeper <zookeeper-host>:2181 --execute --reassignment-json-file reassignment.json
  ```

---

### **5. 검증 및 모니터링**
1. 클러스터의 모든 브로커 상태 확인:
   ```bash
   /opt/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server <new-broker>:9092
   ```
2. 토픽 파티션이 고르게 분포되었는지 확인:
   ```bash
   /opt/kafka/bin/kafka-topics.sh --describe --bootstrap-server <any-broker>:9092
   ```
3. Kafka 클러스터의 상태를 JMX 또는 모니터링 도구(예: Prometheus, Grafana)로 모니터링합니다.

---

### **주의 사항**
1. 새 브로커 추가 시에는 **ZooKeeper 또는 KRaft 컨트롤러가 설정되어 있어야** 합니다.
2. 리어사인 작업 중에는 클러스터에 부하가 발생할 수 있으므로, 트래픽이 적은 시간대에 진행하는 것이 좋습니다.
3. 클러스터 확장 후 Kafka 설정을 업데이트하여 **모든 브로커가 새로운 브로커를 인식**하도록 해야 합니다.

위 단계를 따라 클러스터를 성공적으로 확장하고 데이터 분배를 최적화할 수 있습니다. 추가 문의 사항이 있으면 말씀해주세요!


-----
