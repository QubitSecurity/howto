### 0. 실행 환경
```
zookeeper HOME 경로 : /opt/apache-zookeeper-3.8.4-bin/
zookeeper 실행 경로 : /opt/apache-zookeeper-3.8.4-bin/bin
zookeeper 설정 파일 : /opt/apache-zookeeper-3.8.4-bin/conf/zoo.cfg
```

### 1. 실행
```
/opt/apache-zookeeper-3.8.4-bin/bin/zkServer.sh  start /opt/apache-zookeeper-3.8.4-bin/conf/zoo.cfg
```

### 2. 종료
```
/opt/apache-zookeeper-3.8.4-bin/bin/zkServer.sh  stop
```

### 3. 설치 파일 삭제
```
sudo rm -rf /opt/apache-zookeeper-3.8.4-bin
```
