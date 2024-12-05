### **1. Quorum Queues와 Mirrored Queues 비교**

RabbitMQ는 Quorum Queues와 Mirrored Queues를 통해 고가용성을 제공합니다. 하지만 **둘은 완전히 다른 동작 방식**을 가지며, 아래와 같이 비교됩니다.

| **특징**              | **Quorum Queues**                           | **Mirrored Queues**                          |
|-----------------------|---------------------------------------------|---------------------------------------------|
| **리더-팔로워 구조**  | 예. 리더 노드 장애 시 팔로워가 자동 승격   | 아니요. Active-Active로 모든 복제본 작동     |
| **복제 메커니즘**     | Raft Consensus Protocol 사용                | 모든 노드에 메시지 동기화                   |
| **성능**              | 고성능, 쓰기 속도가 느릴 수 있음           | 복제 오버헤드로 쓰기 및 읽기 속도 저하      |
| **사용 시기**         | 고가용성과 일관성이 필요한 경우             | 단순 고가용성 및 더 빠른 페일오버를 원하는 경우 |
| **RabbitMQ 버전 요구**| 3.8 이상                                   | 모든 버전에서 사용 가능                    |

#### 결론:
1. **Quorum Queues**는 리더-팔로워 구조를 제공하므로, 리더 장애 시 자동 승격 기능이 필요하면 추가 설정 없이 Quorum Queues를 사용하면 충분합니다.
2. **Mirrored Queues**는 더 오래된 방식이며, RabbitMQ 3.8 이상에서는 Quorum Queues가 권장됩니다.

---

### **2. Quorum Queues 설정**

RabbitMQ 3.8 이상부터 Quorum Queues가 도입되었습니다. 버전이 맞다면, Quorum Queues를 구성하기 위해 별도의 정책 설정이 필요하지 않으며, 큐를 선언할 때 `x-queue-type`을 `quorum`으로 설정하면 됩니다.

#### 예시:
큐를 생성할 때 다음 명령을 실행하면 됩니다.

```bash
rabbitmqadmin declare queue name=myqueue durable=true \
  arguments='{"x-queue-type":"quorum", "x-quorum-replication-factor":3}'
```

위 명령이 동작하지 않는다면, RabbitMQ 버전을 확인하시고 다음을 검토하세요:
- **RabbitMQ 버전**: 3.8 이상이어야 Quorum Queues를 지원합니다.
- **Management Plugin 활성화**: `rabbitmqadmin` 명령을 사용하려면 Management Plugin이 활성화되어 있어야 합니다.
  ```bash
  rabbitmq-plugins enable rabbitmq_management
  ```

---

### **3. Mirrored Queues 정책 설정**

RabbitMQ 3.7 이하 또는 Mirrored Queues가 필요한 경우, 정책을 설정하여 복제를 활성화할 수 있습니다. 하지만 Mirrored Queues는 Quorum Queues의 완전한 대안이 아니므로, 최신 RabbitMQ에서는 사용을 피하는 것이 좋습니다.

#### 정책 설정 예제:
```bash
rabbitmqctl set_policy ha-all "^.*$" '{"ha-mode":"all"}'
```

이 명령은 모든 큐를 클러스터의 모든 노드에 복제합니다. 설정되지 않는다면:
- **CLI 버전 불일치**: `rabbitmqctl` 버전이 실행 중인 RabbitMQ 서버와 호환되지 않을 수 있습니다.
- **정책 문법 확인**: 일부 버전에서는 정책 설정 JSON 문법이 달라질 수 있으므로, 정확한 문법을 확인해야 합니다.

---

### **4. RabbitMQ 4.0.3 가정 및 지원 여부**

RabbitMQ 4.x 버전이 존재하지 않는 점을 고려할 때, 버전 확인이 필요합니다. RabbitMQ의 **버전을 확인**하려면 다음 명령을 실행하십시오:

```bash
rabbitmqctl status
```

출력에서 `RabbitMQ version` 정보를 확인하십시오. Quorum Queues를 지원하지 않는 구버전(3.8 미만)을 사용하는 경우, 다음 중 하나를 선택해야 합니다:
1. RabbitMQ 업그레이드.
2. Mirrored Queues로 대체.

---

### **결론**

1. RabbitMQ 3.8 이상 버전에서는 **Quorum Queues**가 마스터-슬레이브 구조를 대체하며, 추가 정책 설정이 필요하지 않습니다.
2. Mirrored Queues는 3.8 이상에서도 사용할 수 있지만, Quorum Queues를 사용하는 것이 더 권장됩니다.
