## single 포트 단일 노드
### 실행 환경
```
HOME 경로 : /opt/solr
DATA 경로 : /opt/solr/server/solr
```

### 실행
```
sudo /opt/solr/bin/solr start -c
```

### 종료
```
sudo /opt/solr/bin/solr stop -all
```


## barematel 다중 포트
### 실행 환경
```
HOME 경로 : /opt/solr
DATA 경로 : /opt/solr/solr[PORT]/data
```

### 실행
```
전체 실행
/opt/solr/start.sh

포트별 실행
/opt/solr/bin/solr start -c -p [PORT] -s /opt/solr/solr8983/data
```

### 종료
```
전체 종료
/opt/solr/bin/solr stop -all

포트별 종료
/opt/solr/bin/solr stop -p [PORT]
```
