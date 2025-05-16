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

### 1.2 LAN 설정
```
(상단 배너)Network →(왼쪽 배너)Interface →(메인) 설정할 포트 지정 
(※ex. GE/0/0/3에서 설정)





```

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

## 3. NAT Policy 설정
### 3.1 NAT Policy 설정
```
(상단 배너)Policy →(왼쪽 배너)NAT Policy →(메인)Add
```

## 4. 구성 확인
```
(상단 배너)Network →(왼쪽 배너)Interface → (메인)Interface List에서 확인 가능.
```
