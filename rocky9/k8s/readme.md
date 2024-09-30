## 0. 사전준비
### 0.1 selinux 비활성화
```
setenforce Permissive
확인
getenforce
```

### 0.2 방화벽 종료
```
방화벽 중지
systemctl stop firewalld
방화벽 비활성화
systemctl disable firewalld
```

### 0.3 네트워크 설정
```
modprobe overlay
modprobe br_netfilter

(영구 적용)
vi /etc/modules-load.d/k8s.conf
overlay
br_netfilter
```

### 0.4 sysctl 파라미터 설정
```
sysctl 파라미터 설정
vi /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1

sysctl 즉시 적용
sysctl --system
```

### 0.5 swap 비활성화
```
swapoff -a
sed -i -e '/swap/d' /etc/fstab
```

## 1. 설치
### 1.1 레포지토리 설정
```
vi /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key

vi /etc/yum.repos.d/cri-o.repo
[cri-o]
name=CRI-O
baseurl=https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/rpm/repodata/repomd.xml.key

레포지토리 참고 URL
https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
```

### 1.2 패키지 설치
```
의존성 패키지 설치
dnf install conntrack container-selinux ebtables ethtool iptables socat
CRI-O 와 Kubeadm 설치
dnf install -y --repo cri-o --repo kubernetes cri-o kubeadm kubectl kubelet
```
### 1.3 패키지 활성화
```
CRI-O, Kublet 활성화
systemctl enable crio
systemctl enable kubelet
서비스 시작
systemctl start crio
확인
systemctl status crio
```

## 2. 멀티노드 구성
### 2.1 멀티노드 기본 구성 형태
```
haproxy 2(master1, backup1)
master 3
worker 3
```

### 2.2 haproxy 설정
```
haproxy 설치
dnf install haproxy
cfg 파일 구성
vi /etc/haproxy/haproxy.cfg
```

### 2.3 클러스터 초기화 설정(1번 master 노드)
```
클러스터 초기화(첫번째 master 진행)
kubeadm init --control-plane-endpoint=10.100.10.100:46443 --upload-certs --pod-network-cidr=192.168.0.0/16
--control-plane-endpoint : haproxy 연결
--pod-network-cidr : pod 네트워크 대역 설정
--upload-certs : control plane 노드 간에 인증서를 공유
노드 생성 확인
kubectl get nodes -o wide

정상 초기화 시, 발생 화면 예시
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of the control-plane node running the following command on each as root:

  kubeadm join 10.100.10.100:46443 --token mampsb.c5v2zpwz2tv591no \
        --discovery-token-ca-cert-hash sha256:8e17a7bd1a787bc92ffea30ac3b16662eaabb49f99fa8419c4231dc1254f53b9 \
        --control-plane --certificate-key 44cfa6b69a8d32063d461c6b4833a1a50b90f2408cf48d8805f3c14861e857e0

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.100.10.100:46443 --token mampsb.c5v2zpwz2tv591no \
        --discovery-token-ca-cert-hash sha256:8e17a7bd1a787bc92ffea30ac3b16662eaabb49f99fa8419c4231dc1254f53b9

```

### 2. master 노드 설정(2,3번 master 노드)
```
위 초기화 시, 결과 내용을 사용하여 설정
예시:
  kubeadm join 10.100.10.100:46443 --token mampsb.c5v2zpwz2tv591no \
        --discovery-token-ca-cert-hash sha256:8e17a7bd1a787bc92ffea30ac3b16662eaabb49f99fa8419c4231dc1254f53b9 \
        --control-plane --certificate-key 44cfa6b69a8d32063d461c6b4833a1a50b90f2408cf48d8805f3c14861e857e0
```
### 3. worker 노드 설정(all worker 노드)
```
위 초기화 시, 결과 내용을 사용하여 설정
예시 :
kubeadm join 10.100.10.100:46443 --token mampsb.c5v2zpwz2tv591no \
        --discovery-token-ca-cert-hash sha256:8e17a7bd1a787bc92ffea30ac3b16662eaabb49f99fa8419c4231dc1254f53b9
```

## 3. CNI(calico) 설정
### 3.1 CNI(calico) 설치
```
첫번째 master 노드 초기화 진행 후 하는 것을 권장.

yaml 파일 다운로드
curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml -O
```
### 3.2 calico.yaml 수정
```
vi calico.yaml
  - name: CALICO_IPV4POOL_CIDR
    value: "192.168.0.0/16  
-> 클러스터 초기화 할때 pod 네트워크 설정과 동일
```
### 3.3 calico 배포
```
yaml 파일 배포
kubectl apply -f calico.yaml
관련 pod 정상 생성 확인
kubectl get pods -o wide -A
crio 재실행
systemctl restart crio
```

## 4. ingress 설정
### 4.1 ingress 설치
```
ingress yaml 다운로드
curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.2/deploy/static/provider/cloud/deploy.yaml -O
```



