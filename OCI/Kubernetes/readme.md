## 0. 설명
OCI(Oracle Cloud Infrastructure)를 통한 Kubernetes 구축
관리형 Kubernetes로, Worker 노드만 생성

## 1. OCI Kubernetes 구축
### 1.1 Compartments 생성
Identity & Security > Compartments > [정의할 Compartments 이름] <br>
![k1](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k1.png) <br>
![k2](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k2.png) <br>
Root Compartments 하위, Child Compartments 로 생성. (Compartments 경로는 상이할 수 있음.) <br>
![k3](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k3.png) <br>
Create Compartments 진행 <br>
![k4](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k4.png) <br>
Child Compartments 생성 확인 <br>
![k5](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k5.png) <br>

<br><br>
### 1.2 Kubernetes Clusters 생성
Developer Services > Kubernetes Clusters (OKE)<br>
![k6](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k6.png) <br>
왼쪽 Compartments 배너에서 사용할 Compartments(1.1 과정에서 정의한 Compartments)를 지정후 Create Cluster <br>
![k7](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k7.png) <br>
Quick create 클릭 <br>
![k8](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k8.png) <br>
클러스터 이름을 정의한 후, 쿠버네티스 형태를 정의.<br>
Kubernetes 구성 선택 (ex. Public endpoint / Managed / Private workers )<br>
![k9](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k9.png) <br>
Worknode CPU, Memory 선택 (ex. Standard.E3.Flex 로 1core / 8GB )<br>
![k10](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k10.png) <br>
OS 선택 (ex. Oracle Linux 8(기본) 선택)<br>
![k11](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k11.png) <br>
Worker Node 수량 설정 (ex. Worker Node 수 3 EA) <br>
![k12](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k12.png) <br>

일정 시간이 지난 후 클러스터와 노드가 생성되었는지 확인
클러스터 상태 확인
![k13](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k13.png) <br>
워커 노드 상태 확인 
Node Pool 내  워커 노드 상태 확인
![k14](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k14.png) <br>
![k15](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k15.png) <br>
![k16](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k16.png) <br>


<br><br><br>
## 2. Bastion 구축 (Worker 노드 제어용)
### 2.1 Bastion 인스턴스 생성
Navigation menu  → 왼쪽 배너 Compute → 오른쪽 배너 Instances  <br>
![k17](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k17.png) <br>
Instances → 하단 Create instance  <br>
![k18](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k18.png) <br>
Compartment: Cluster가 위치한 Compartment 선택 (Placement는 기본 값)  <br><br>
![k19](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k19.png) <br>
Instance OS 및 CPU, Memory 지정 (ex. oracle Linux 8 / VM.Standard.E4.Flex, Cpu:1, Memory:16 GB) <br>
![k20](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k20.png) <br>

Network 설정 <br>
VNIC name: 임의 지정(공백일 시, 자동으로 이름 생성) <br>
Virtual cloud network compartment: Cluster가 위치한 Compartment 선택 <br>
Virtual cloud network: cluster에서 만든 vcn 선택. <br>
Subnet: create-public subnet → public subnet 생성. <br>
New subnet name: 임의 지정. <br>
Compartment: Cluster가 위치한 Compartment 선택 <br>
CIDR block : 다른 Subnet과 겹치지 않도록 범위 설정. <br>
![k21](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k21.png) <br>

Primary VNIC IP addresses <br>
create-public subnet 선택 시, 해당 옵션 조정 불가. (※ 새로운 Subnet 대신, Kubernetes Cluster 생성시 같이 생성된 Public Subnet 사용해도 무방) <br>
![k22](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k22.png) <br>
ssh 공개 키 업로드. (사용 가능한 ssh key 쌍이 없는 경우, Generate a key pair for me 체크를 통해 생성 및 추출 가능) <br>
![k23](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k23.png) <br>
Bastion Instance 생성 확인<br>
![k24](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k24.png) <br>

<br><br>
### 2.2 Tenancy ocid 확인
User ocid 확인<br>
OCI 클라우드 오른쪽 위 프로필 아이콘 클릭  →Profile 하단 User settings 클릭.<br>
![k39](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k39.png) <br>
계정 profile →User information → 하단 OCID 
user OCID 조회 및 복사 가능.
![k40](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k40.png) <br>

Tenancy.ocid 확인 <br>
OCI 클라우드 오른쪽 위 프로필 아이콘 클릭  →Profile 하단 Tenancy 클릭.<br>
![k41](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k41.png) <br>


Tenancy details 하단 →Tenancy information→OCID <br>
tenancy OCID 조회 및 복사 가능. <br>
![k42](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k42.png) <br>


<br><br>
### 2.3 Bastion oci-cli 설치
Python3 업데이트 <br>
Repository 업데이트 <br>
sudo dnf -y update <br>
python 모듈 Repository 확인 <br>
sudo dnf module list | grep python <br>
![k25](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k25.png) <br>
python3.9 버전 Repository 활성화 <br>
sudo dnf -y module enable python39 <br>
python3.9 버전 설치 <br>
sudo dnf -y install python39 <br>
기본 python 버전 변경 <br>
sudo alternatives --config python3(python 39로 변경) <br> <br>


oci-cli 설치 <br>
wget https://github.com/oracle/oci-cli/releases/download/v3.54.0/oci-cli-3.54.0.zip <br>
unzip -d /root  ./oci-cli-3.54.0.zip <br>
pip3 install /root/oci-cli/oci_cli-*-py3-none-any.whl <br> <br>

oci-cli 설정 <br>
oci setup config <br>
![k43](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k43.png) <br>
cat /root/.oci/oci_api_key_public.pem <br>
![k27](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k27.png) <br>
오른쪽 상단 프로필 클릭 > User settings > 좌측 API keys <br>
![k28](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k28.png) <br>
api key 연동 확인 (확인되는데 5분정도 소요) <br>
oci os ns get<br>
![k29](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k29.png) <br>


<br> <br>
### 2.4 Bastion Kubernetes 연동
```
kubectl 설치
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" 
cp ./kubectl /sbin/
chmod 755 /sbin/kubectl 
```

k8s 연동<br>
콘솔 > Container > Clusters > 해당 OKE Cluster 클릭 > Access Cluster <br>
![k30](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k30.png) <br>
Local Access에서 필요한 config 내용 복사 (ex. public endpoint 사용) <br>
![k31](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k31.png) <br>
bastion에서 실행 및 Worker Node 연결 확인 <br>
![k32](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k32.png) <br>


<br><br><br>
## 3. Container Registry 구성
### 3.1 image pull/push 테스트(ex. Test Image - nginx)
docker 설치 <br>
dnf install docker <br><br>

auth token 생성 <br>
오른쪽 상단 프로필 클릭 > User settings > 좌측 Auth tokens <br><br>
![k33](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k33.png) <br>
생성 시 반드시 복사 해야 한다 close 하면 다시 확인할 수 없어 재생성 필요.

docker 방식 Container Register 로그인 <br>
docker login ap-seoul-1.ocir.io <br>
Username: <register 네임스페이스>/<oci 계정> <br>
ex . Username: cnxxxxxxxxxxxxx2/user@testc.com    <br>
Passward: <생성 token 값> <br>
![k33](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k33.png) <br>

<br><br>
```
※ 참고사항
OCI Container Register 주소(offial)
https://docs.oracle.com/en-us/iaas/Content/Registry/Concepts/registryprerequisites.htm#Availab

사용 리전 주소 <br>
https://ap-seoul-1.ocir.io (OC1 realm only)
https://icn.ocir.io (OC1 realm only)
https://artifacts.ap-seoul-1.oci.oraclecloud.com
```

이미지 pull 및 확인(Bastion 로컬)  <br>
docker image pull nginx <br>
docker images <br>
![k35](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k35.png) <br>  <br>

이미지 태그  <br>
docker tag nginx ap-seoul-1.ocir.io/<register 네임스페이스>/test-nginx:1.0.demo  <br>
docker images  <br>
![k36](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k36.png) <br>  <br>

이미지 push  <br>
docker push ap-seoul-1.ocir.io/<register 네임스페이스>/test-nginx:1.0.demo  <br>
![k37](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k37.png) <br>  <br>

이미지 삭제(Bastion 로컬) <br>
podman ps -a -q | xargs -r podman rm -f <br>
podman images -q | xargs -r podman rmi -f <br>
docker images <br>


이미지 pull <br> 
docker pull ap-seoul-1.ocir.io/<register 네임스페이스>/test-nginx:1.0.demo <br>
docker images <br>
![k38](https://github.com/QubitSecurity/howto/blob/main/OCI/Kubernetes/images/k38.png) <br>  <br>

k8s 시크릿 생성 및 확인<br>
kubectl create secret docker-registry ocirsecret --docker-server=ap-seoul-1.ocir.io --docker-username='<register 네임스페이스>/<oci 계정>' --docker-password='<생성 token 값>' --docker-email='<oci 계정>' <br>
kubectl get secrets <br>


