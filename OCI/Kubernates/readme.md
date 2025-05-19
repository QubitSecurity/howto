### 0. 설명
OCI를 통한 Kubernates 구축

## 1. OCI Kubernates 구축
### 1.1 Compartments 생성
Identity & Security > Compartments > qubitsec 
※ RootCompartments 하위, Child Compartments 로 생성.

Create Compartments 진행

Child Compartments 생성 확인


### 1.2 Kubernate Clusters 생성
Developer Services > Kubernetes Clusters (OKE)

왼쪽 Compartments 배너에서 사용할 Compartments(1.1 과정에서 정의한 Compartments)를 지정후 Create Cluster

Quick create 로 진행하여 필요한 구성요소를 한번에 생성.

클러스터 이름을 정의한 후, 쿠버네티스 형태를 정의.
여기는 Public endpoint / Managed / Private workers 로 진행
스펙도 기존 선택 VM. Standard.E3.Flex 로 1core / 8GB 로 진행
OS는 Oracle Linux 8(기본 선택) 진행
Node 수는 3개 설정 

일정 시간이 지난 후 클러스터와 노드가 생성되었는지 확인
클러스터 상태 확인

워커 노드 상태 확인 
Node Pool 내  워커 노드 상태 확인

## 2. Bastion 구축
### 2.1 Bastion 인스턴스 생성
Navigation menu  → 왼쪽 배너 Compute → 오른쪽 배너 Instances 

Instances → 하단 Create instance 

Compartment: Cluster가 위치한 Compartment 선택 

Placement: 설정된 값으로 두기 

Image: oracle Linux 8 
Shape: VM.Standard.E4.Flex, Cpu:1, Memory:16 GB로 설정.


VNIC name: 임의 지정(공백일 시, 자동으로 이름 생성)
Virtual cloud network compartment: Cluster가 위치한 Compartment 선택 

Virtual cloud network: cluster에서 만든 vcn 선택.

Subnet: create-public subnet → public subnet 생성.

New subnet name: 임의 지정.

Compartment: Cluster가 위치한 Compartment 선택 
CIDR block : 다른 Subnet과 겹치지 않도록 범위 설정.

Primary VNIC IP addresses
create-public subnet 선택 시, 해당 옵션 조정 불가.

ssh 공개 키 업로드.
없을 시, Generate a key pair for me 체크를 통해 획득 가능.

생성 확인


### 2.2 Bastion oci-cli 설치
Repository 업데이트
sudo dnf -y update
python 모듈 Repository 확인
sudo dnf module list | grep python
python3.9 버전 Repository 활성화
sudo dnf -y module enable python39
python3.9 버전 설치
sudo dnf -y install python39
기본 python 버전 변경
sudo alternatives --config python3(python 39로 변경)


oci-cli 설치
wget https://github.com/oracle/oci-cli/releases/download/v3.54.0/oci-cli-3.54.0.zip

unzip -d /root  ./oci-cli-3.54.0.zip

pip3 install /root/oci-cli/oci_cli-*-py3-none-any.whl

oci-cli 설정
oci setup config

cat /root/.oci/oci_api_key_public.pem

오른쪽 상단 프로필 클릭 > User settings > 좌측 API keys


api key 연동 확인 (확인되는데 까지 시간이 좀 걸림.5분 정도? .)
oci os ns get


### 2.3 Bastion kubernates 연동
kubectl 설치
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

cp ./kubectl /sbin/
chmod 755 /sbin/kubectl


k8s 연동
콘솔 > Container > Clusters > 해당 OKE Cluster 클릭 > Access Cluster

Local Access 에서 public endpoint 값 복사 

bastion에서 실행


## 3. Container Registry 구성
### 3.0 image pull/push 테스트
- docker 설치
dnf install docker

- auth token 생성
오른쪽 상단 프로필 클릭 > User settings > 좌측 Auth tokens

생성 시 반드시 복사 해야 한다 close 하면 다시 확인할 수 없어 재생성 필요.

- docker 방식 Container Register 로그인
docker login ap-seoul-1.ocir.io
Username: <register 네임스페이스>/<oci 계정>
ex . Username: cnywokhfsxm2/hugo@qubitsec.com   
Passward: <생성 token 값>
cnywokhfsxm2/hugo@qubitsec.com

※ 참고사항 - OCI Container Register 주소(offial)
https://docs.oracle.com/en-us/iaas/Content/Registry/Concepts/registryprerequisites.htm#Availab

※ 참고사항 - 사용 리전 주소
https://ap-seoul-1.ocir.io (OC1 realm only)
https://icn.ocir.io (OC1 realm only)
https://artifacts.ap-seoul-1.oci.oraclecloud.com


- bastion 로컬 환경 nginx 이미지 pull 및 확인
docker image pull nginx
docker images


- 이미지 태그
docker tag nginx ap-seoul-1.ocir.io/<register 네임스페이스>/test-nginx:1.0.demo
docker images


- 이미지 push
docker push ap-seoul-1.ocir.io/<register 네임스페이스>/test-nginx:1.0.demo


- bastion 로컬 환경 저장 이미지 삭제
podman ps -a -q | xargs -r podman rm -f
podman images -q | xargs -r podman rmi -f
docker images


- 이미지 pull
docker pull ap-seoul-1.ocir.io/<register 네임스페이스>/test-nginx:1.0.demo
docker images


- k8s 시크릿 생성
kubectl create secret docker-registry ocirsecret --docker-server=ap-seoul-1.ocir.io --docker-username='<register 네임스페이스>/<oci 계정>' --docker-password='<생성 token 값>' --docker-email='<oci 계정>'

- 시크릿 확인
kubectl get secrets


