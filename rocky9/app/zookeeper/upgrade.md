### 1. 신규 버전 zookeeper 다운로드
```
cd /opt
wget https://dlcdn.apache.org/zookeeper/zookeeper-3.9.4/apache-zookeeper-3.9.4-bin.tar.gz
tar xvf /opt/apache-zookeeper-3.9.4-bin.tar.gz
```

### 2. 설정 파일 복사
```
cp -r /opt/zk/data /opt/apache-zookeeper-3.9.4-bin/
cp /opt/zk/config/zoo.cfg /opt/apache-zookeeper-3.9.4-bin/config/
```

### 3. 이전 zookeeper 종료
```
/opt/zk/bin/zkServer.sh stop
```

### 4. 신규 버전 zookeeper 심볼릭링크 생성
```
rm /opt/zk
ln -s /opt/apache-zookeeper-3.9.4-bin /opt/zk
※시작 종료 방법은 동일
```
