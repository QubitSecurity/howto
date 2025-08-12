# 시스템 상태 점검 스크립트 모음

이 저장소는 주요 백엔드 시스템의 상태를 자동으로 점검하기 위한 스크립트 모음입니다.  
모든 점검은 수동 실행 또는 자동화 도구(예: Ansible)와 연동하여 운영 환경에서 활용할 수 있습니다.

---

## 1. 개별 서비스 상태 점검 [👉](./check-status.md)
- 단일 서비스 상태 확인용 기본 스크립트
- HTTP 응답, 포트 오픈 여부 등을 체크

## 2. MySQL: Replication 지연 점검 [👉](./check-mysql.md)
- 마스터-슬레이브 간 `Seconds_Behind_Master` 수치 확인
- `ssh` 기반 원격 접속 필요
- Ansible 인벤토리 및 인증 설정 필요

## 3. Kafka 상태 점검 [👉](./check-kafka.md)
- 브로커 응답 상태 확인
- `kafka-topics.sh`, `zookeeper` 접속 여부 및 지연 상태 점검 포함 가능

## 4. Redis 상태 점검 [👉](./check-redis.md)
- Master/Slave 역할 정상 동작 여부 확인
- CLUSTER NODES 기반 상태 분석

---

## 9. MSA Filter 점검 [👉](./eureka/check_filter.sh)
- 마이크로서비스 구조 내 Eureka 기반 필터 상태 확인
- 등록 여부, 응답 상태, 구성 체크

---

## X. 데이터 병합 및 최적화 작업 [👉](About-optimize.md)
- 로그 병합 및 데이터 정리 자동화
- 불필요한 데이터 제거 및 정렬

---
