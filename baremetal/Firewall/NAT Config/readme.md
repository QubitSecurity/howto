## 0. 사전 설명
```
Huawei 방화벽 장비를 이용한 기본 NAT 설정
실제 설정은 Web 콘솔 페이지를 사용(사전 Web 콘솔 활성화 필요)
```



## 1. WAN/LAN 설정
### 1.1 WAN 설정
```
(상단 배너) Network → (왼쪽 배너) Interface → (메인) 설정할 포트 지정
(※ ex. WAN0/0/0 에서 설정)
```
![f1](https://github.com/QubitSecurity/howto/blob/main/baremetal/Firewall/NAT%20Config/images/f1.png)
![f2](https://github.com/QubitSecurity/howto/blob/main/baremetal/Firewall/NAT%20Config/images/f2.png)
![f3](https://github.com/QubitSecurity/howto/blob/main/baremetal/Firewall/NAT%20Config/images/f3.png)

### 1.2 LAN 설정
```
(상단 배너)Network →(왼쪽 배너)Interface →(메인) 설정할 포트 지정 
(※ex. GE/0/0/3에서 설정)
```
![f4](https://github.com/QubitSecurity/howto/blob/main/baremetal/Firewall/NAT%20Config/images/f4.png)
![f5](https://github.com/QubitSecurity/howto/blob/main/baremetal/Firewall/NAT%20Config/images/f5.png)
![f6](https://github.com/QubitSecurity/howto/blob/main/baremetal/Firewall/NAT%20Config/images/f6.png)

### 1.3 설정 설명
```
General Settings 
Alias: 인터페이스의 식별용 이름.
Virtual System: 해당 인터페이스가 속한 가상 시스템
Zone: 인터페이스가 소속된 보안 영역
Mode: 운영 모드 (Routing, Switching, Bypass 등)

IPv4
IP Address: 인터페이스에 설정할 IPv4 주소 (서브넷 마스크 포함)
Default Gateway: 기본 게이트웨이 주소 (라우팅의 출구 역할)
Primary DNS Server: 주 DNS 서버 주소 (도메인 이름 해석용)
Secondary DNS Server: 보조 DNS 서버 주소 (주 DNS 장애 시 사용)
Multi-Egress Options: 다중 WAN 경로 사용 시 트래픽 분산 또는 우선순위 지정 설정 메뉴

Interface Bandwidth
Ingress Bandwidth: 외부에서 들어오는 트래픽의 대역폭 제한 설정
Egress Bandwidth: 내부에서 나가는 트래픽의 대역폭 제한 설정
Access Management: 해당 인터페이스를 통해 방화벽에 접근 가능한지 여부 설정

Advanced
Negotiation: 속도 및 Duplex 모드 자동 협상 여부 설정
IPv4 MTU: IPv4 패킷의 최대 전송 단위 (Maximum Transmission Unit) 설정
IPv6 MTU: IPv6 패킷의 최대 전송 단위 (Maximum Transmission Unit) 설정
```

## 2. Security Policy 설정
### 2.1 Security Policy 설정
```
(상단 배너)Policy →(왼쪽 배너)Security Policy →(메인) Add Security Policy
```
![f7](https://github.com/QubitSecurity/howto/blob/main/baremetal/Firewall/NAT%20Config/images/f7.png)
![f8](https://github.com/QubitSecurity/howto/blob/main/baremetal/Firewall/NAT%20Config/images/f8.png)

### 2.2 Security Policy 설정 설명
```
General Settings 
Name: 정책 이름.
Description: 정책에 대한 설명
Policy Group: 정책이 소속될 그룹. (그룹 단위로 정책 관리 시 사용)
Tag: 태그 지정. 

Source and Destination
Source Zone: 패킷이 들어오는 보안 영역 (예: trust, DMZ)
Destination Zone: 패킷이 나가는 보안 영역 (예: untrust, WAN)
Source Address/Region: 출발지 주소나 주소 그룹, 또는 지역
Destination Address/Region: 목적지 주소나 주소 그룹, 또는 지역
VLAN ID: 해당 정책이 적용되는 VLAN ID (있는 경우만 설정)

User and Service
Action: 정책 동작. (Permit, Deny, Monitor 등)

Other Options
Record Traffic Logs: 트래픽 로그 기록 여부
Record Policy Matching Logs: 어떤 정책이 트래픽을 잡았는지 로그 기록.
Record Session Logs: 세션 생성/종료 로그 기록.
Session Aging Time: 세션 유지 시간 설정 (초 단위, 예: 600초)
User-Defined Persistent Connection (SP): 사용자 정의 지속 연결 설정, 특정 트래픽에 대한 세션 유지 목적.

```


## 3. NAT Policy 설정
### 3.1 NAT Policy 설정
```
(상단 배너)Policy →(왼쪽 배너)NAT Policy →(메인)Add
```
![f9](https://github.com/QubitSecurity/howto/blob/main/baremetal/Firewall/NAT%20Config/images/f9.png)
![f10](https://github.com/QubitSecurity/howto/blob/main/baremetal/Firewall/NAT%20Config/images/f10.png)
### 3.2 NAT Policy 설정 설명
```
General Settings 
NAT Type: 사용할 NAT의 유형 설정 (예: Source NAT, Destination NAT 등)
NAT Mode: NAT 처리 방식 선택 (예: Easy IP, Address Pool, No-PAT 등)
Schedule: NAT 정책의 동작 시간 설정 (스케줄 지정 가능)

Original Data Packet 
Source Zone: 트래픽의 출발지 보안 영역
Destination Type: 목적지의 유형 (예: IP, Domain, Interface 등)
Source Address: 원본 트래픽의 출발지 주소
Destination Address: 원본 트래픽의 목적지 주소
Service: 적용할 서비스/프로토콜 (예: HTTP, FTP, Any 등)

Translated Data Packet 
Source Address Translated To: 변환될 출발지 주소
Address in the IP address pool: 사용할 주소 풀 내 IP
Outbound Interface: NAT 처리 후 트래픽이 나갈 인터페이스
```



## 4. 구성 확인
```
(상단 배너)Network →(왼쪽 배너)Interface → (메인)Interface List에서 확인 가능.
```
![f11](https://github.com/QubitSecurity/howto/blob/main/baremetal/Firewall/NAT%20Config/images/f11.png)
![f14](https://github.com/QubitSecurity/howto/blob/main/baremetal/Firewall/NAT%20Config/images/f14.png)
![f13](https://github.com/QubitSecurity/howto/blob/main/baremetal/Firewall/NAT%20Config/images/f13.png)
