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

### 1.2 LAN 설정
```
(상단 배너)Network →(왼쪽 배너)Interface →(메인) 설정할 포트 지정 
(※ex. GE/0/0/3에서 설정)

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
