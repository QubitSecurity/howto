### 0. 실행 환경
```
zookeeper HOME 경로 : /opt/zk/
zookeeper 실행 경로 : /opt/zk/bin
zookeeper 설정 파일 : /opt/zk/conf/zoo.cfg
```

### 1. 실행
```
/opt/zk/bin/zkServer.sh  start /opt/zk/conf/zoo.cfg
```

### 2. 종료
```
/opt/zk/bin/zkServer.sh  stop
```

### 3. 설치 파일 삭제
```
sudo rm -rf /opt/apache-zookeeper-X.X.X-bin
※심볼릭 링크 확인
```
