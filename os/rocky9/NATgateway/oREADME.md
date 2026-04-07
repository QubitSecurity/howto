## 0. 사전 작업

### 0.1 ipv4 허용
```
sysctl -w net.ipv4.ip_forward=1
sysctl -p

영구 허용
vi /etc/sysctl.conf
net.ipv4.ip_forward = 1
```

## 1. iptables 설정
### 1.1 iptables 설정
```
iptables -t nat -A POSTROUTING -o enp7s0 -s 10.100.0.0/255.255.0.0 -j SNAT  --to-source XXX.XXX.XXX.XXX
옵션 설명
iptables : 명령어
-t nat : nat 테이블
-A POSTROUTING : 정책 체인
-o eth0 : output 인터페이스
-s 10.100.0.0/255.255.0.0 : 출발지 주소
-j SNAT : 정책 실행
--to-source XXX.XXX.XXX.XXX : 바꿀 출발지 주소

전역 설정
iptables -t nat -A POSTROUTING -o enp7s0 -j MASQUERADE
```

### 1.2 iptables 서비스 설치
```
dnf install iptables-services
```
### 1.3 iptables 규칙 저장
```
service iptables save
```

## 기타 명령어
```
룰 확인
iptables -t nat -L -n -v

룰 삭제
1. 룰 라인 확인
iptables -t nat -L POSTROUTING -n -v --line-numbers
2. 룰 삭제
iptables -t nat -D POSTROUTING 1
```


