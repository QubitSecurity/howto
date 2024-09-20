## 0. 사전준비

### 0.1 시스템 사양
```
가상 머신 사양
vcpu 32
mem 64
disk 80
```

### 0.2 사전 확인
```
시스템 Default GW 설정
외부 연결(NAT or Proxy)
노드 간 통신 가능 확인
방화벽 확인
```

## 1. 멀티 노드 구성(master)

### 1.1 마스터 설치
```
curl -sfL https://get.k3s.io | sh -s - server --cluster-init
```
### 1.2 기본 pod 확인
```
kubectl -n kube-system get pod
```
### 1.3기본 node 확인
```
kubectl get nodes -o wide
```

## 2. 멀티 노드 구성(worker)
### 2.1 토큰 확인
```
cat /var/lib/rancher/k3s/server/node-token
K10cdd9c5b7df47e671d488a8386e7ad479728816ba95f038094ecaf72f9be91343::server:a11a81ea25ef3273a800b7050d6b9934
```
### 2.2 worker 설치
```
curl -sfL https://get.k3s.io | K3S_URL=https://10.100.5.150:6443 K3S_TOKEN=K10cdd9c5b7df47e671d488a8386e7ad479728816ba95f038094ecaf72f9be91343::server:a11a81ea25ef3273a800b7050d6b9934 sh -
```

### 2.3 프록시 설정 시,
```
(master)
vi/etc/systemd/system/k3s.service.env
http_proxy="http://10.100.5.180:3128"
https_proxy="http://10.100.5.180:3128"
no_proxy="localhost,127.0.0.1,registry.qubitsec.internal,10.100.*.*"

vi /etc/systemd/system/k3s.service
[Service]
Type=notify
EnvironmentFile=-/etc/default/%N
EnvironmentFile=-/etc/sysconfig/%N
EnvironmentFile=-/etc/systemd/system/k3s.service.env  --> 추가


(worker)
vi /etc/systemd/system/k3s-agent.service.env
K3S_TOKEN="K10cdd9c5b7df47e671d488a8386e7ad479728816ba95f038094ecaf72f9be91343::server:a11a81ea25ef3273a800b7050d6b9934"
K3S_URL="https://10.100.5.150:6443"
http_proxy="http://10.100.5.180:3128"
https_proxy="http://10.100.5.180:3128"
no_proxy="localhost,127.0.0.1,registry.qubitsec.internal,10.100.*.*,10.100.5.150"

vi /etc/systemd/system/k3s-agent.service
[Service]
Type=notify
EnvironmentFile=-/etc/default/%N
EnvironmentFile=-/etc/sysconfig/%N
EnvironmentFile=-/etc/systemd/system/k3s-agent.service.env --> 추가
```

## 참고 :
```
https://devocean.sk.com/blog/techBoardDetail.do?ID=165375
https://blog.ggaman.com/1020
```

