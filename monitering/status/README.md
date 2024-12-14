`Solr`, `Kafak`, `Redis`, `MySQL` 등 다양한 어플리케이션 상태를 점검합니다.

---

## 1. Solr 상태 점검
- [ ] Solr Collection Status=OK 인지 점검합니다.

```
# Usage: ./check_disk_solr_status.sh <SOLR_URL> <COLLECTION_NAME>

./check_disk_solr_status.sh http://10.100.41.69:8983 solr-syslog

cat check_status_solr-syslog.log

./check_disk_solr_status.sh http://10.100.61.69:8983 solr-weblog

cat check_status_solr-weblog.log
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

---

## 4. MySQL 상태 점검
- [ ] Status=OK 인지 점검합니다.

```
# Usage: ./check_mysql_status.sh <master_host.txt> <slave_host.txt>

cat check_status_mysql.log
```

---


