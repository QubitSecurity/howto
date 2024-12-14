# 250-ansible
Ansible 을 이용하여 서버의 상태를 점검한다.

## 1. Disk 사용량 점검
- [ ] 70%, 80%와 같이 특정 사용량 이상을 점검합니다.
- [ ] check_disk_usage_?percent.log 파일에 저장됩니다.

```
# Usage: ./check_disk_usage.sh <THRESHOLD%> <ANSIBLE_GROUP> [--debug]

./check_disk_usage.sh 70% solr-weblog

cat check_disk_usage_70percent.log

./check_disk_usage.sh 70% solr-syslog

cat check_disk_usage_75percent.log
```

---

## 2. Solr 상태 점검
- [ ] Solr Collection Status=OK 인지 점검합니다.

```
# Usage: ./check_disk_solr_status.sh <SOLR_URL> <COLLECTION_NAME>

./check_disk_solr_status.sh http://10.100.41.69:8983 solr-syslog

cat check_status_solr-syslog.log

./check_disk_solr_status.sh http://10.100.61.69:8983 solr-weblog

cat check_status_solr-weblog.log
```

---

## 9. 시간 동기화 점검
- [ ] ntpdate
- [ ] chrony

```
# ./ntp/a_ntpdate.sh
# ./ntp/a_chrony.sh
```

---
