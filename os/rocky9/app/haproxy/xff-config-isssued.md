
# HAProxy 3.2.20 xff 설정 이슈 정리


---

## 1. 접속 테스트 구성

```mermaid
graph LR;
   Client[Client PC<br>192.168.10.39]
   Proxy1["Proxy1<br>192.168.10.253<br>(172.16.18.253)"]
   Proxy2[Proxy2<br>172.16.10.200]
   Haproxy[Haproxy<br>172.16.18.35]
   WEB[Nginx<br>172.16.183.37]
        
   Client --> Proxy1 --> Proxy2 --> Haproxy --> WEB

```
```
Client PC -> Proxy1 -> Proxy2 -> Haproxy -> Nginx
접속 테스트는 http 프로토콜(https 테스트 불가)

1. Client PC 는 브라우저 or curl를 사용하여 Proxy1를 통해 Web 접속
2  Proxy1 은
   1) 자신(Proxy1)xff 를 생성, Haproxy 접속
   2) Proxy2 경유 자신(Proxy2) XFF 추가 생성, haproxy 접속
3. haproxy 는 xff 를 재구성하여 nginx 접속
4. Nginx 에서 웹 access 로그 확인
```

---
## 2. 사전 설정
Squid xff 설정
```
request_header_access X-Forwarded-For allow all
forwarded_for on
```


## 3. haproxy xff 구성 설정 별 테스트 및 결과

### 3.1 설정 req.hdr
```
http-request set-header X-Forwarded-For %[src],%[req.hdr(X-Forwarded-For)] if { req.hdr(X-Forwarded-For) -m found }
```

### 3.1 테스트 및 웹 로그 결과
```
브라우저
192.168.10.35 - - [01/Jul/2026:09:44:30 +0900] "GET / HTTP/1.1" 200 7620 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 Edg/122.0.0.0" "172.16.10.200,172.16.18.253"
```
```
curl-pattern-1
curl -k -x "http://proxy" -H "X-Forwarded-For: 1.1.1.1"  http://domain/
192.168.10.35 - - [01/Jul/2026:10:17:18 +0900] "GET /a HTTP/1.1" 404 3332 "-" "curl/8.19.0" "172.16.10.200,172.16.18.253"
```
```
curl-pattern-2
curl -k -x "http://proxy" -H "X-Forwarded-For: 1.1.1.1.,2.2.2.2" http://domain/
192.168.10.35 - - [01/Jul/2026:10:18:26 +0900] "GET /a HTTP/1.1" 404 3332 "-" "curl/8.19.0" "172.16.10.200,172.16.18.253"
```
```
curl-pattern-3
curl -k -x "http://proxy" -H "X-Forwarded-For: 1.1.1.1" -H "X-Forwarded-For: 3.3.3.3"  http://domain
192.168.10.35 - - [01/Jul/2026:10:19:11 +0900] "GET /a HTTP/1.1" 404 3332 "-" "curl/8.19.0" "172.16.10.200,172.16.18.253"
```
### 3.1 결과
```
xff 필드 좌측 데이터는 haproxy 확인 src 주소
그 뒤로 경유 과정의 src 앞단 주소 확인
즉 src 이전의 하나의 주소만 확인 가능(경유가 없다면, 임의 지정 xff 필드 단일 주소 확인)
```
---


### 3.2 설정 req.fhdr
```
http-request set-header X-Forwarded-For %[src],%[req.fhdr(X-Forwarded-For)] if { req.fhdr(X-Forwarded-For) -m found }
```
### 3.2 테스트 및 웹 로그 결과
```
브라우저
192.168.10.35 - - [01/Jul/2026:10:22:52 +0900] "GET /favicon.ico HTTP/1.1" 404 3332 "http://haproxy.plura.io/" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 Edg/122.0.0.0" "172.16.10.200,192.168.10.39, 172.16.18.253"
```
```
curl-pattern-1
curl -k -x "http://proxy" -H "X-Forwarded-For: 1.1.1.1"  http://domain/
192.168.10.35 - - [01/Jul/2026:10:23:47 +0900] "GET /a HTTP/1.1" 404 3332 "-" "curl/8.19.0" "172.16.10.200,1.1.1.1, 192.168.10.39, 172.16.18.253"
```
```
curl-pattern-2
curl -k -x "http://proxy" -H "X-Forwarded-For: 1.1.1.1.,2.2.2.2" http://domain/
192.168.10.35 - - [01/Jul/2026:10:23:41 +0900] "GET /a HTTP/1.1" 404 3332 "-" "curl/8.19.0" "172.16.10.200,1.1.1.1,2.2.2.2, 192.168.10.39, 172.16.18.253"
```
```
curl-pattern-3
curl -k -x "http://proxy" -H "X-Forwarded-For: 1.1.1.1" -H "X-Forwarded-For: 3.3.3.3"  http://domain
192.168.10.35 - - [01/Jul/2026:10:29:37 +0900] "GET /a HTTP/1.1" 404 3332 "-" "curl/8.19.0" "172.16.10.200,1.1.1.1, 3.3.3.3, 192.168.10.39, 172.16.18.253"
```
### 3.2 결과
```
xff 필드 좌측 데이터는 haproxy 확인 src 주소
그 뒤로 헤더 임의 지정 xff 데이터, Client, 경유 IP 순 확인
모든 IP주소 확인 가능
```
---


### 3.3 설정 req.allhdr
```
동기
client -> haproxy -> nginx (squid가 없는 구조) 일때,
client가 아래 패턴와  curl-pattern-3 형식 실행 시, 임의 지정된 xff 정보를 로그에 생성하지 못함.
```
```mermaid
graph LR;
   Client[Client PC]
   Haproxy[Haproxy]
   WEB[Nginx]
        
   Client --> Haproxy --> WEB

```
### 3.3 테스트 및 웹 로그 결과
```
curl-pattern-3 (curl -k -x "http://proxy" -H "X-Forwarded-For: 1.1.1.1" -H "X-Forwarded-For: 3.3.3.3"  http://domain)
192.168.10.35 - - [01/Jul/2026:10:36:34 +0900] "GET / HTTP/1.1" 200 7620 "-" "curl/8.6.0" "172.16.30.250,5.5.5.5"
즉 1.1.1.1 정보는 확인되지 않음.
```
### 3.3 결과
```
xff 필드 좌측 데이터는 haproxy 확인 src 주소
그 뒤로 헤더 임의 지정 xff 데이터
먼저 임의 지정된 xff 정보 중, 제일 마지막 데이터만 남음.

이를 해결하기 위해 allhdr fetch 함수를 생성, 모든 데이터를 확인하는 함수 필요.
allhdr는 haproxy가 제공하는 함수가 아니기에, http_fetch.c 소스에 관련 코드를 포함하여 재빌드.
재빌드 후 아래와 같이 설정
http-request set-var(txn.xff) req.allhdr(X-Forwarded-For)
http-request set-header X-Forwarded-For %[src],%[var(txn.xff)]
```
- [allhdr 재빌드](https://github.com/QubitSecurity/howto/blob/main/rocky9/app/haproxy/allhdr.md)
---



