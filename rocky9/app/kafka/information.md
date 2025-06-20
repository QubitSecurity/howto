## **Apache Kafka** 

### **정의**

: 실시간 스트리밍 데이터를 고속으로 처리하고 전달하는 **분산형 메시지 큐 시스템,**  
데이터를 **발행(Publish),** **구독(Subscribe),  처리(Process), 저장(Store)**할 수 있는 기능을 갖춘 시스템.

---

**주요 역할**  
**\-** 데이터 이동, 저장, 스트림 처리.

* Messaging: 실시간 데이터 전송 (pub/sub) 

* Storage: 디스크에 데이터 장기간 보관 가능 (디폴트 7일, 조정 가능) 

* Processing: Kafka Streams, ksqlDB 등을 통해 실시간 데이터 처리 가능

---

**핵심 개념**

###  **Producer**

* 데이터를 Kafka로 전송하는 클라이언트

* 메시지를 특정 Topic에 발행

* 메시지의 Key를 기반으로 파티션을 지정하거나, 기본 파티셔너로 자동 분배

---

### **Topic**

* 메시지를 논리적으로 구분하는 단위 (예: `orders`, `logs`)

* 여러 개의 Partition으로 구성될 수 있음

---

### **Partition**

* Topic을 물리적으로 분할한 단위

* 메시지는 각 파티션에 순차적으로 저장됨

* 병렬 처리 가능 → 처리 성능 향상

---

### 

### **Offset**

* 파티션 내 메시지의 고유 위치값

* Consumer는 Offset 기준으로 메시지를 읽고, 처리 완료 지점을 커밋함

---

### **Consumer**

* Kafka에서 메시지를 읽는 클라이언트

* Topic을 구독하고, 파티션 단위로 메시지를 읽음

* 읽은 위치(Offset)를 저장하여 이어서 처리 가능

---

### **Consumer Group**

* 여러 Consumer를 하나의 그룹으로 묶어 병렬 처리 가능

* 하나의 파티션은 그룹 내 단 하나의 Consumer만 소비

* 다른 Consumer Group은 같은 메시지를 독립적으로 읽을 수 있음

---

### **Broker**

* Kafka 서버 한 대를 의미

* 메시지를 저장하고 Producer/Consumer의 요청을 처리

* 여러 Broker가 모여 Cluster를 구성

---

 ### **Cluster**

* 여러 Broker로 구성된 Kafka 전체 시스템

* 고가용성 및 확장성 제공

* 하나의 Controller Broker가 존재하여 전체 상태를 관리

---

### 

### 

### **Controller**

* 클러스터 내에서 자동으로 선출된 Broker

* 파티션 리더 지정, Broker 상태 감시 등의 역할 수행

---

 

### **Rebalancing**

* Consumer Group에 변화가 생기면 파티션 할당을 재조정하는 과정

* 이 과정에서 일시적으로 메시지 소비 중단 발생 가능

---

### **Replication**

* 파티션 데이터를 다른 Broker에 복제하여 저장

* 리더/팔로워 구조: 리더만 읽기/쓰기, 팔로워는 백업

* 리더 장애 시 팔로워가 승격 → 고가용성 확보
---

### 

### 

### **Kafka 클러스터 방식** 

: Zookeeper, KRaft 방식(3.3버전 이후)

| 항목 | Zookeeper 방식 | KRaft 방식 |
| ----- | ----- | ----- |
| **메타데이터 저장** | **Zookeeper** | **Kafka 내부 로그** |
| **컨트롤러 선출** | **Zookeeper** | **Kafka (Raft 합의, 투표 방식)** |
| **장애 감지/복구** | **Zookeeper** | **Kafka 자체 처리** |
| **구성 요소** | **Kafka \+ Zookeeper** | **Kafka 단독** |
| **실서비스 안정성** | **검증 완료** | **3.3 이상부터 실사용 권장** |
| **기본 모드 전환** | **해당 없음** | **Kafka 3.6부터 기본값** |
