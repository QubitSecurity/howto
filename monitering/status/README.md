`Solr`, `Kafak`, `Redis`, `MySQL` 등 다양한 어플리케이션 상태를 점검합니다.

---

## 0. 스케줄러 동작
- [ ] 매2분마다 자동으로 동작하면 프로그램 동작 상태를 확인한다.

```bash
# Usage: ./schedule_script.sh

tail -f check_status_solr-weblog.log
```

## 1. Solr 상태 점검
- [ ] Solr Collection Status=OK 인지 점검합니다.

```
# Usage: ./check_solr_status.sh <SOLR_URL> <COLLECTION_NAME>

./check_solr_status.sh http://10.100.41.69:8983 solr-syslog

cat check_status_solr-syslog.log

./check_solr_status.sh http://10.100.61.69:8983 solr-weblog

cat check_status_solr-weblog.log
```

```log
$ tail check_status_solr-weblog.log
2024-12-14 09:56:46 | Status=OK, Solr_URL=http://10.100.61.69:8983, Collection=solr-weblog
2024-12-18 13:34:34 | CRITICAL: 9 core(s) are in recovering state on Solr instance http://10.100.61.69:8983, collection solr-weblog
2024-12-18 14:38:53 | CRITICAL: 10 core(s) are in down state on Solr instance http://10.100.61.69:8983, collection solr-weblog
```

---

## 2. Kafka Brocker 상태 점검
- [ ] Topic=sys || Topic=web, Lag=0 인지 점검합니다.

```
# Usage: ./check_kafka_status.sh <KAFKA_BROKERS_FILE>

cat check_status_kafka.log
```
---

## 3. Redis 상태 점검
- [ ] Redis Cluster Status=OK 인지 점검합니다.

```
# Usage: ./check_redis_status.sh

cat check_status_redis.log
```

```log
$ tail check_status_redis.log
2024-12-18 13:47:57 | Status=OK, Redis Cluster is running properly with 5 masters and 5 slaves on port 6381
```

---

## 4. MySQL 상태 점검
- [ ] Status=OK 인지 점검합니다.

```
# Usage: ./check_mysql_status.sh <master_host.txt> <slave_host.txt>

cat check_status_mysql.log
```

---

## 5. 병합
- [병합을 위한 shard 정보 수집 방법](About-optimize.md)

