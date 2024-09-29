**Elasticsearch**는 더 이상 완전한 오픈 소스 소프트웨어로 제공되지 않습니다. 2021년에 Elasticsearch 개발사인 **Elastic**은 라이선스를 **SSPL(Server Side Public License)** 및 **Elastic License**로 변경했습니다. 이러한 라이선스 변경으로 인해, Elasticsearch는 이전의 **Apache 2.0** 라이선스에서 벗어나 더 제한적인 사용 조건을 갖게 되었습니다. 이는 많은 기업과 오픈 소스 커뮤니티에서 Elasticsearch를 자유롭게 사용하고 배포하는 데 영향을 주었습니다.

### OpenSearch: Elasticsearch의 대안
**OpenSearch**는 이러한 라이선스 변경에 대한 대안으로 Amazon Web Services(AWS)에서 주도하여 만든 프로젝트입니다. Elasticsearch와 Kibana의 포크(fork) 버전이며, 완전한 오픈 소스(Apache 2.0 라이선스)로 제공됩니다.

- **OpenSearch**는 Elasticsearch 7.10.2(마지막 Apache 2.0 버전)를 기반으로 하며, 이후 독자적으로 개발되고 있습니다. 
- **OpenSearch Dashboards**는 Kibana의 포크로, 데이터 시각화와 대시보드 기능을 제공합니다.

### OpenSearch의 주요 특징
- **완전한 오픈 소스**: Apache 2.0 라이선스로 제공되어 자유롭게 사용, 수정, 배포가 가능합니다.
- **Elasticsearch와 호환성**: Elasticsearch의 기존 API와 호환성을 유지하므로, 대부분의 Elasticsearch 클라이언트와 도구를 사용하여 쉽게 OpenSearch로 전환할 수 있습니다.
- **커뮤니티 주도**: AWS가 주도하지만, 커뮤니티의 다양한 기여를 통해 지속적으로 발전하고 있습니다.

### 요약
- **Elasticsearch**는 현재 SSPL 및 Elastic License를 채택하고 있어 더 이상 완전한 오픈 소스가 아닙니다.
- **OpenSearch**는 Elasticsearch의 오픈 소스 대안으로, Elasticsearch의 기능과 호환성을 유지하면서도 Apache 2.0 라이선스로 제공됩니다. 

따라서, 오픈 소스 소프트웨어에 의존하는 환경에서는 OpenSearch가 Elasticsearch의 좋은 대안이 될 수 있습니다.

<hr/>

**EKL** 스택은 Elasticsearch, Kibana, Logstash의 조합을 가리킵니다. 이 세 가지를 오픈 소스 대안으로 대체하려면 **OpenSearch** 프로젝트의 구성 요소들을 사용할 수 있습니다. 각각에 대응하는 OpenSearch 버전과 Logstash의 상태를 살펴보겠습니다.

### OpenSearch로의 대안:
1. **Elasticsearch → OpenSearch**:
   - OpenSearch는 Elasticsearch의 오픈 소스 포크입니다. Elasticsearch의 기능을 거의 그대로 유지하면서, 새로운 오픈 소스 기능을 추가하고 있습니다.
   
2. **Kibana → OpenSearch Dashboards**:
   - OpenSearch Dashboards는 Kibana의 포크 버전으로, Elasticsearch 데이터를 시각화하고 분석할 수 있는 기능을 제공합니다. 기존 Kibana 사용자들이 대시보드를 OpenSearch Dashboards에서 손쉽게 사용할 수 있도록 호환성을 유지하고 있습니다.

3. **Logstash**:
   - **Logstash**는 여전히 오픈 소스로 유지되고 있으며, Apache 2.0 라이선스로 제공됩니다. 따라서 OpenSearch와도 함께 사용할 수 있습니다.
   - 그러나 OpenSearch 프로젝트에서는 Logstash와 유사한 기능을 수행하는 **Data Prepper**라는 오픈 소스 도구를 제공하고 있습니다. Data Prepper는 데이터 수집과 처리에 최적화되어 있으며, OpenSearch로의 데이터 인덱싱을 지원합니다.

### 요약:
- **Elasticsearch** → **OpenSearch**: Elasticsearch의 오픈 소스 대안.
- **Kibana** → **OpenSearch Dashboards**: Kibana의 오픈 소스 대안.
- **Logstash**: 여전히 오픈 소스이며 OpenSearch와도 함께 사용 가능하지만, OpenSearch에서는 **Data Prepper**를 추가적인 데이터 처리 도구로 제공합니다.

따라서, 기존의 EKL 스택을 오픈 소스로 유지하고 싶다면 OpenSearch, OpenSearch Dashboards, 그리고 Logstash를 조합하여 사용하면 됩니다.
