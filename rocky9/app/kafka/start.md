## 1. kafka
### 1.0. 실행 환경
```
HOME 경로 : /opt/kafka/bin/qubit_kafka_start.sh
설정 파일 :/opt/kafka/config/server.propertise
DATA 경로 : /opt/kafka/kafka-data/kafka-logs
```

### 1.1. 실행
```
sudo /opt/kafka/bin/qubit_kafka_start.sh
```

### 1.2. 종료
```
sudo /opt/kafka/bin/kafka-server-stop.sh
```



## 2. CMAK
### 2.0. 실행 환경
```
HOME 경로 : /opt/cmak
실행 파일 경로 : /etc/systemd/system/cmak.service
설정 파일 : /opt/cmak/cmak-X.X.X.X/conf/application.conf
```
### 2.1. 실행
```
sudo systemctl start cmak
```
### 2.2. 종료
```
sudo systemctl stop cmak
```
## 3. AKHQ
### 3.0. 실행 환경
```
HOME 경로 : /opt/akhq
실행 파일 경로 : /etc/systemd/system/akhq.service
설정 파일 : /opt/akhq/akhq-X.XX.X/config/application.yml
```
### 3.1. 실행
```
sudo systemctl start cmak
```
### 3.2. 종료
```
sudo systemctl stop cmak
```
