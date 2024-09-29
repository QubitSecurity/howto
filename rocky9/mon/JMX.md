JMX(Java Management Extensions)는 Kafka, Zookeeper, Solr 등 Java 기반 애플리케이션의 성능 및 상태를 모니터링하는 데 활용되는 기술입니다. 각 애플리케이션이 노출하는 다양한 메트릭을 수집하고 관리하는 데 사용되며, Prometheus와 같은 모니터링 도구와도 연동될 수 있습니다. 아래에 각 시스템을 JMX를 통해 모니터링하는 방법을 자세히 설명하겠습니다.

### 1. **JMX란?**
   - JMX는 Java 애플리케이션의 모니터링 및 관리를 위한 프레임워크입니다.
   - Java 애플리케이션이 자체 상태와 성능을 나타내는 메트릭(MBeans)을 노출할 수 있게 해주며, 이러한 메트릭은 JMX 프로토콜을 통해 외부에서 접근할 수 있습니다.
   - JMX를 통해 JVM 메모리 사용량, 스레드 수, 애플리케이션별 성능 메트릭 등을 확인할 수 있습니다.

### 2. **Kafka 모니터링 with JMX**
   - **Kafka**는 브로커, 토픽, 파티션, 프로듀서, 컨슈머 등의 다양한 측면에서 상태 및 성능을 나타내는 메트릭을 제공합니다.
   - Kafka는 JMX를 통해 이러한 메트릭을 노출하며, 대표적인 Kafka 메트릭은 다음과 같습니다:
     - `kafka.server`: 브로커의 상태, 메시지 처리량, 파티션 리더 상태 등.
     - `kafka.network`: 네트워크 요청 및 응답 상태.
     - `kafka.log`: 로그 세그먼트 및 파일 수.
     - `kafka.controller`: 클러스터 리더 상태 및 이벤트 처리량.
   - **설정**: Kafka 브로커를 실행할 때 `JMX_PORT` 환경 변수를 설정하여 JMX 인터페이스를 활성화할 수 있습니다.
     ```bash
     export JMX_PORT=9999
     ```
   - 이로써 외부 모니터링 도구가 JMX를 통해 Kafka 브로커의 상태를 모니터링할 수 있습니다.

### 3. **Zookeeper 모니터링 with JMX**
   - **Zookeeper**는 Kafka의 메타데이터 및 클러스터 관리를 지원하는 필수 구성 요소로, 여러 메트릭을 JMX를 통해 노출합니다.
   - Zookeeper의 대표적인 JMX 메트릭은 다음과 같습니다:
     - `zk_server_state`: Zookeeper 인스턴스의 상태(Follower, Leader 등).
     - `num_alive_connections`: 클라이언트 연결 수.
     - `outstanding_requests`: 처리 대기 중인 요청 수.
   - **설정**: Zookeeper는 기본적으로 JMX를 통해 메트릭을 노출하도록 설정되어 있습니다. 환경 변수 `JMX_PORT`를 설정하여 Zookeeper의 JMX 모니터링을 활성화할 수 있습니다.
     ```bash
     export JMX_PORT=9998
     ```

### 4. **Solr 모니터링 with JMX**
   - **Solr**는 검색 플랫폼으로, 검색 속도, 인덱싱, 캐시 상태 등 다양한 메트릭을 JMX를 통해 제공합니다.
   - 대표적인 Solr의 JMX 메트릭은 다음과 같습니다:
     - `solr.core`: 코어별 검색 요청 수, 인덱싱 처리량, 에러 발생 건수 등.
     - `solr.cache`: 검색 캐시의 상태와 히트율.
     - `solr.jvm`: JVM 메모리 사용량, 가비지 컬렉션 상태 등.
   - **설정**: Solr를 실행할 때 `SOLR_OPTS`에 JMX 설정을 추가하여 JMX 모니터링을 활성화할 수 있습니다.
     ```bash
     export SOLR_OPTS="$SOLR_OPTS -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9997 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"
     ```

### 5. **JMX를 이용한 통합 모니터링**
   - **Prometheus JMX Exporter**: Kafka, Zookeeper, Solr의 JMX 메트릭을 수집하여 Prometheus와 같은 모니터링 시스템에 통합하는 방법이 일반적입니다. JMX Exporter는 JMX를 HTTP 엔드포인트로 노출해 Prometheus가 데이터를 스크랩할 수 있도록 해줍니다.
     - 각 애플리케이션(Kafka, Zookeeper, Solr)에서 JMX Exporter를 설정하고, 해당 엔드포인트를 Prometheus에 등록하여 메트릭을 수집합니다.
   - **Grafana**: Prometheus와 연동하여 수집된 메트릭을 시각화하고 대시보드로 관리할 수 있습니다.

### 6. **요약**
   - **JMX**는 Kafka, Zookeeper, Solr과 같은 Java 기반 시스템의 상태와 성능 메트릭을 모니터링하는 표준 방법입니다.
   - 각 시스템은 JMX를 통해 JVM 관련 메트릭과 애플리케이션별 메트릭을 외부로 노출하며, 이를 통해 실시간으로 애플리케이션의 상태를 파악할 수 있습니다.
   - Prometheus와 같은 모니터링 도구와 연동하여 JMX 데이터를 수집하고, Grafana로 시각화하는 것이 일반적인 모니터링 방식입니다.
