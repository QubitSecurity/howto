# 250-ansible
Ansible 을 이용하여 서버의 상태를 점검한다.

## 1. Disk 사용량 점검
- [ ] 70%, 80%와 같이 특정 사용량 이상을 점검합니다.
- [ ] check_disk_usage_?percent.log 파일에 저장됩니다.

```
# Usage: ./scripts/check_disk_usage.sh <THRESHOLD%> <ANSIBLE_GROUP> [--debug]

./check_disk_usage.sh 70% solr-weblog

cat check_disk_usage_70percent.log

./check_disk_usage.sh 70% solr-syslog

cat check_disk_usage_75percent.log
```

---
## 2. Disk 사용량 점검
- [ ] 마스터 DB에 test_insert_table 테이블을 만들어 INSERT 테스트 수행
- [ ] INSERT 실패 또는 SELECT 확인 실패 시 문제로 간주
- [ ] 실패 시 메일로 알림 전송

```
# Usage: ./scripts/mysql_insert_check.sh
```

---



---
## 9. 시간 동기화 점검
- [ ] ntpdate
- [ ] chrony

```
# ./ntp/a_ntpdate.sh
# ./ntp/a_chrony.sh
```

---
