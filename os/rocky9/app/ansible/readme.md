### 0. 사전작업

#### 0.1 ssh key 생성
````
ssh-keygen -t rsa -b 2048
````
#### 0.2 ssh key 복사
````
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
````
#### 0.3 ssh key 전송
````
ssh-copy-id qubit@XXX.XXX.XXX.XXX
※XXX.XXX.XXX.XXX : Original VM
````

#### 0.4 ssh 접속 테스트
````
ssh qubit@XXX.XXX.XXX.XXX
````

### 1. ansible 설치
```
dnf -y install ansible
```

### 2. 작업 디렉토리 복사 
```
cp -R /etc/ansible /etc/qubit/ansbile
```
### 3. 작업 디렉토리 권한 수정
```
chown -R qubit:qubit /etc/qubit/ansible
```



