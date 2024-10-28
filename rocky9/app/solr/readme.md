### 1.0. 실행 환경
```
HOME 경로 : /opt/solr
실행 파일 경로 : /etc/systemd/system/solr[PORT].service
DATA 경로 : /opt/solr/solr[PORT]/data
```

### 1.1. 실행
```
sudo systemctl start solr[PORT]
```

### 1.2. 종료
```
sudo systemctl stop solr[PORT]
