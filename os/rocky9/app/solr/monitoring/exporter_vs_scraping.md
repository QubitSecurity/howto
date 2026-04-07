Apache Solr 모니터링을 Prometheus + Grafana로 구성할 때 크게 **두 가지 방식**이 있습니다.

1️⃣ **Solr Exporter 방식**
2️⃣ **Direct Prometheus Scrape 방식**

두 방식은 구조, 운영 난이도, 기능 범위가 꽤 다릅니다. 아래에서 **구조 → 동작 방식 → 장단점 → 실무 사용 패턴** 순서로 자세히 설명드리겠습니다.

---

# 1️⃣ Solr Exporter 방식

## 구조

```
Prometheus
     │
     │ scrape
     ▼
Solr Exporter
     │
     │ Solr Metrics API
     ▼
Solr Node
```

Exporter는 **Solr metrics API를 호출해서 Prometheus 형식으로 변환하는 중간 서비스**입니다.

---

## 동작 방식

Solr exporter는 다음 API를 사용합니다.

```
/admin/metrics
/admin/collections
/admin/cores
```

Exporter가 하는 역할

1️⃣ Solr metrics API 호출
2️⃣ JSON metrics 수집
3️⃣ config.xml rule 적용
4️⃣ Prometheus format 변환
5️⃣ `/metrics` endpoint 제공

Prometheus는 exporter의 `/metrics` 를 scrape합니다.

---

## exporter 실행 예

```bash
solr-exporter \
-p 9854 \
-z zk1:2181,zk2:2181,zk3:2181/solr \
-b http://solr1:8983/solr \
--config-file solr-exporter-config.xml
```

옵션 설명

| 옵션            | 설명                  |
| ------------- | ------------------- |
| -p            | exporter 포트         |
| -z            | Zookeeper 연결        |
| -b            | Solr base URL       |
| --config-file | metric mapping rule |

---

## exporter config 구조

대표적인 설정 예

```xml
<metrics>
  <lst name="request">
    <lst name="query">
      <str name="path">/admin/metrics</str>
      <lst name="params">
        <str name="expr">solr\.core\..*:QUERY\..*</str>
      </lst>
    </lst>
  </lst>
</metrics>
```

역할

* 어떤 Solr metric을 수집할지 결정
* metric name 변환
* label 정의

---

## exporter가 생성하는 metric 예

```
solr_query_requests_total
solr_update_requests_total
solr_core_num_docs
solr_cache_hitratio
solr_searcher_num_docs
```

즉 **Solr metrics → Prometheus metric으로 매핑**합니다.

---

## exporter 방식 장점

✔ Solr 6 / 7에서도 사용 가능
✔ metric 이름 정규화
✔ metric filtering 가능
✔ cluster discovery 지원

---

## exporter 방식 단점

❌ exporter 프로세스 필요
❌ config.xml 관리 필요
❌ metric 누락 가능
❌ exporter 장애 가능
❌ SolrCloud discovery 문제 발생 가능
❌ 운영 복잡도 증가

실무에서 가장 많이 발생하는 문제

```
collection discovery 실패
metric regex mismatch
config.xml 오류
```

---

# 2️⃣ Direct Prometheus Scrape 방식

Solr 8.4 이후부터 **Prometheus format endpoint가 기본 제공됩니다.**

endpoint

```
/solr/admin/metrics?wt=prometheus
```

---

## 구조

```
Prometheus
     │
     │ scrape
     ▼
Solr Node
```

Exporter가 없습니다.

---

## Prometheus 설정

```yaml
scrape_configs:
  - job_name: solr
    metrics_path: /solr/admin/metrics
    params:
      wt: ['prometheus']
    static_configs:
      - targets:
        - solr1:8983
        - solr2:8983
```

---

## 제공되는 metric

예시

```
solr_metrics_core_update_handler
solr_metrics_core_cache_filter_cache_hitratio
solr_metrics_jvm_memory_heap_used
solr_metrics_node_cores
```

metric 이름 구조

```
solr_metrics_<category>_<metric>
```

label 예

```
collection
core
shard
replica
handler
category
```

---

## Direct Scrape 장점

✔ exporter 필요 없음
✔ 설정 매우 단순
✔ 모든 Solr metric 제공
✔ metric 누락 없음
✔ 운영 안정성 높음
✔ SolrCloud 자동 지원

---

## Direct Scrape 단점

❌ metric 이름이 길고 복잡
❌ metric filtering 어려움
❌ label 구조 복잡

---

# 3️⃣ 구조 비교

| 항목           | Solr Exporter                | Direct Scrape     |
| ------------ | ---------------------------- | ----------------- |
| 구조           | Prometheus → Exporter → Solr | Prometheus → Solr |
| 프로세스         | exporter 필요                  | 없음                |
| 설정           | config.xml 필요                | 없음                |
| metric 변환    | 가능                           | 불가                |
| metric 수     | 제한적                          | 전체                |
| 운영 난이도       | 높음                           | 낮음                |
| SolrCloud 지원 | exporter 구현 의존               | 기본 지원             |
| 장애 가능성       | exporter 장애                  | 없음                |

---

# 4️⃣ metric 차이

### exporter 방식

metric 이름이 단순

```
solr_query_requests_total
solr_update_requests_total
solr_core_num_docs
```

---

### direct scrape

label 기반

```
solr_metrics_core_update_handler{category="QUERY",collection="syslog"}
```

PromQL 예

```
sum by(collection)(
rate(solr_metrics_core_update_handler{category="QUERY"}[1m])
)
```

---

# 5️⃣ 실무 사용 비율

대략적인 체감 비율

| 방식            | 사용         |
| ------------- | ---------- |
| Solr Exporter | 20~30%     |
| Direct Scrape | **70~80%** |

특히 다음 환경에서는 거의 100% direct scrape

* Solr 9
* Kubernetes
* Cloud
* Observability stack

---

# 6️⃣ 실무 추천 방식

Solr 버전 기준

| Solr version | 추천                |
| ------------ | ----------------- |
| Solr 6       | exporter          |
| Solr 7       | exporter          |
| Solr 8       | direct scrape     |
| Solr 9       | **direct scrape** |

---

# 7️⃣ 실제 운영 아키텍처

보통 이렇게 구성합니다.

```
Solr Cluster
     │
     │ /admin/metrics?wt=prometheus
     ▼
Prometheus
     ▼
Grafana
     ▼
Alertmanager
```

사용 도구

* Apache Solr
* Prometheus
* Grafana
* Alertmanager

---

# 8️⃣ 결론

현재 환경(Solr 9 기준)

👉 **Direct Prometheus Scrape가 가장 좋은 방식입니다.**

이유

1️⃣ 구조 단순
2️⃣ metric 완전 노출
3️⃣ exporter 장애 없음
4️⃣ 운영 부담 최소

---

💡 원하시면 다음도 설명드릴 수 있습니다.

* **Solr Prometheus metric 구조 완전 설명 (core / node / jvm / cache)**
* **Solr Grafana 대시보드 설계 (30패널 실무 템플릿)**
* **Solr 장애 탐지용 Prometheus alert rule**

실무에서 Solr 운영할 때 **가장 중요한 모니터링 지표 15개**도 같이 정리해 드릴 수 있습니다.
