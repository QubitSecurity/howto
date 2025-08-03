# 🚀 SolrCloud on Docker: 운영 안정화 가이드

이 저장소는 Docker 기반으로 대규모 Apache SolrCloud 클러스터를 안정적으로 운영하기 위한  
설계 원칙과 구성 요소를 문서화한 기술 가이드입니다.

---

## 📌 핵심 개념 요약

✔️ **1. Persistent Volume을 사용한 데이터 보존**  
→ 컨테이너 재시작 시에도 Solr 인덱스와 설정 유지

✔️ **2. 리소스 제한 및 할당 정확하게 설정**  
→ `--cpus`, `--memory`, `-Xmx` 등 JVM과 Docker 리소스 일치

✔️ **3. 적절한 모니터링 & 자동화 도입**  
→ Prometheus + Solr Exporter로 검색/색인 상태 실시간 추적

✔️ **4. 컨테이너 관리 툴(Docker Compose, Kubernetes 등) 활용**  
→ DevOps 기반 자동화 배포 및 고가용성 클러스터 구성

✔️ **5. 컨테이너 기반 대용량 Solr**  
→ 구성의 적정성 여부 설명

---

## 📁 문서 구조

| No.  | 파일명 | 설명 |
|---|--------|------|
|1| [`sys-configuration.md`](./docker/sys-configuration.md) | 컨테이너 내 Solr 설정, 디스크 마운트, restart 정책 등 |
|2| [`precise-resource-control.md`](./docker/precise-resource-control.md) | Solr JVM 힙 설정 및 Docker 리소스 제한 방법 |
|3| [`adaptive-monitoring.md`](./docker/adaptive-monitoring.md) | Prometheus, Grafana 기반 Solr 상태 모니터링 설정 |
|4| [`orchestration-tools.md`](./docker/orchestration-tools.md) | Docker Compose vs Kubernetes 운영 비교 및 Helm/Operator 사용법 |
|5| [`consider-large-scale.md`](./docker/consider-large-scale.md) | 대규모 노드 구성 시 고려해야 할 구조 설계 및 스토리지 전략 |

---

## 🗂 예시: 디렉토리 구성

```bash
/solr-cluster/
├── docker-compose.yml
├── prometheus/
│   └── prometheus.yml
├── solr-exporter/
│   └── solr-exporter-config.xml
├── volumes/
│   ├── solr-a1_home/
│   ├── solr-a2_home/
│   └── zk-data/
└── docs/
    ├── adaptive-monitoring.md
    ├── consider-large-scale.md
    ├── ...
````

---

## ✅ 추천 운영 방안

* Dev 환경: Docker Compose로 빠르게 구성
* 운영 환경: Kubernetes + Solr Operator
* 모니터링: Prometheus + Grafana 대시보드
* 백업 전략: host volume 기준 rsync or snapshot

---

## 📬 문의 및 기여

이 프로젝트는 대용량 검색 인프라 운영을 자동화하려는 사용자들을 위해 공개되었습니다.
피드백이나 Pull Request는 언제든 환영합니다!
