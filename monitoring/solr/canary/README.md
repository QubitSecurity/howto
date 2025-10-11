# Canary 기반 Solr 쓰기-읽기 점검

이 스크립트는 SolrCloud의 상태가 정상(그린)처럼 보여도 **실제 업데이트가 막힌 상황**을 탐지합니다.
- `update?commitWithin`으로 작은 문서 1건을 쓰고, `/get`으로 조회 확인
- 응답의 `responseHeader.rf`(Achieved Replication Factor) 확인
- 실패 시 `solr_status_retry.sh`가 60초 간격으로 최대 3회까지 재시도/알림

## 준비
1. (권장) canary 전용 컬렉션 생성:
   ```bash
   curl "http://<host>:8983/solr/admin/collections?action=CREATE&name=monitor_canary&numShards=1&replicationFactor=1&collection.configName=_default"
````

2. (선택) `ts_dt` 필드 추가(청소 기능 사용 시 필수):

   ```bash
   curl -X POST -H 'Content-Type: application/json' \
     "http://<host>:8983/solr/monitor_canary/schema" \
     -d '{"add-field":{"name":"ts_dt","type":"pdate","stored":true}}'
   ```
3. `solr_config-*.conf`에서 `MIN_RF`, 인증정보, 컬렉션명 등을 환경에 맞게 수정

## 실행/동작

* 정상 시: syslog(`logger -t solr_check`)에 OK 로그, 상태 파일 `/tmp/down_<host>_canary_write.log`를 `0`으로 초기화
* 실패 시: 재시도 스크립트가 60초 간격 재확인(최대 3번). 3회차에 메일 통보
* 복구 시: 다음 성공 시 상태 파일 `0`으로 초기화 및 복구 로그 기록
* 청소: `USE_TS_FIELD=true`일 때 매시 `CLEANUP_AT_MINUTE`에 `ts_dt` 기준 오래된 canary 문서 삭제

## FAQ

* TLS가 자체서명인 경우 `CURL_INSECURE=true`
* 인증이 필요한 경우 `SOLR_BASIC_AUTH` 또는 `SOLR_BASIC_AUTH_FILE` 사용
* 잦은 알림 방지: 3회차 이후에는 상태 파일이 `3`으로 유지되어 반복 메일을 억제, 성공 시에만 0으로 초기화

---

## 🧪 테스트 방법 (장애 유도)

> **테스트는 운영 영향이 적은 `monitor_canary` 컬렉션에서만** 진행하세요.

1) **readOnly 강제** → 모든 update가 403  
```bash
# 켜기
curl "http://<host>:8983/solr/admin/collections?action=COLLECTIONPROP&name=monitor_canary&property=readOnly&value=true"
# 끄기
curl "http://<host>:8983/solr/admin/collections?action=COLLECTIONPROP&name=monitor_canary&property=readOnly&delete=true"
````

2. **잘못된 Basic Auth** → 401/403
   `solr_config-*.conf`의 `SOLR_BASIC_AUTH`를 임시로 틀리게 설정 후 1~2분 관찰

3. **디스크 부족/FS read-only 시뮬레이션**
   테스트용 노드에서 디스크 가득 채우기(주의) 또는 read-only 마운트(주의)

> 장애 시 `/var/log/solr_canary_*.log`·syslog, `/tmp/down_*canary_write.log`의 카운터 증가, 3회차에 메일 발송을 확인하세요.

---

## 🔎 운영 팁

* **MIN_RF**는 실제 복제수에 맞춰 엄격하게 잡을수록, “리더는 응답했지만 레플리카 반영 지연” 같은 미묘한 문제를 더 빨리 포착할 수 있습니다.
* `--no-retry` 모드는 **재시도 스크립트 내부 재확인**용이며, 일반 실행에서는 사용하지 않습니다.
* canary 스크립트는 **장애 시에도 이유(HTTP 코드/`status`/`rf`/`error.msg`)** 를 syslog에 남깁니다. 장애 원인 분석에 유용합니다.

---
