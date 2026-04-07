Kafka의 **Zookeeper 모드**와 **KRaft(Kafka Raft Metadata mode)** 모드를 비교하면 다음과 같습니다:

---

### ✅ Kafka Zookeeper 모드 vs KRaft 모드 (Kafka Raft mode)

| 항목              | Zookeeper 모드 (기존 방식)            | KRaft 모드 (신규 방식, Kafka Raft)                                                    |
| --------------- | ------------------------------- | ------------------------------------------------------------------------------- |
| **메타데이터 저장 위치** | Zookeeper                       | Kafka 내부 (KRaft controller 노드)                                                  |
| **외부 의존성**      | 필요 (Zookeeper 클러스터 필요)          | 없음 (Kafka 자체 메타데이터 관리)                                                          |
| **구성 복잡도**      | 높음 (Zookeeper + Kafka 구성)       | 낮음 (Kafka만 구성)                                                                  |
| **리더 선출 방식**    | Zookeeper를 통해 선출                | Raft 프로토콜 기반 내장 선출                                                              |
| **장애 복구**       | Zookeeper가 장애 시 전체 영향           | controller quorum만 유지되면 정상                                                      |
| **메타데이터 일관성**   | eventual consistency            | strong consistency (Raft)                                                       |
| **운영/관리**       | Zookeeper 모니터링 별도 필요            | Kafka 내에서 통합 관리 가능                                                              |
| **기능 지원**       | 모든 기능 완전 지원 (안정적)               | 일부 기능만 지원 (버전에 따라 제한됨)                                                          |
| **클러스터 업그레이드**  | Kafka/Zookeeper 모두 고려 필요        | Kafka만 업그레이드 고려                                                                 |
| **사용 가능 버전**    | Kafka 0.8.x \~ 3.x (현재까지 널리 사용) | Kafka 2.8+ (Preview), Kafka 3.3+ (Production Ready), Kafka 4.0 이상 (ZK 완전 제거 예정) |
| **보안 및 인증**     | Kafka+Zookeeper 인증 설정 모두 필요     | Kafka 내부 인증만 설정 가능 (간결)                                                         |
| **이중 관리 포인트**   | 있음 (Kafka + Zookeeper 관리 필요)    | 없음 (Kafka 단일 관리)                                                                |

---

### 🧭 어떤 상황에 어떤 모드를 선택해야 하나요?

| 상황                               | 권장 모드                          |
| -------------------------------- | ------------------------------ |
| 운영 중 Kafka 3.x 이하 사용             | **Zookeeper 모드 (안정성 높음)**      |
| 신규 구축 Kafka 3.3+ 또는 Kafka 4.x 계획 | **KRaft 모드 (단일 구성, 미래 지향적)**   |
| 기존 시스템과 호환성 중요                   | Zookeeper                      |
| 단순한 구성과 유지보수 원하는 경우              | KRaft                          |
| 수백 개 이상의 토픽/브로커 관리 필요            | **KRaft (더 빠르고 일관된 메타데이터 처리)** |

---

### 📝 참고 사항

* **KRaft 모드에서는 `controller.quorum.voters` 설정이 필수**입니다. (ZK가 없기 때문에 controller 선출이 내부적으로 이루어짐)
* **Kafka 4.0부터 Zookeeper 모드는 제거 예정**입니다. 중장기적으로는 **KRaft 모드로의 전환이 필수**입니다.

---

