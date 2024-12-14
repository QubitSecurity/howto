# System 상태 점검

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
