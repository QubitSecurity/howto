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



