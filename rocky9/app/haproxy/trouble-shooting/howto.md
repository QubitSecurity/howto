## 1) 지금까지 진행 내용 요약

### 관측된 증상

* PLURA‑WAF 1대 단독일 때는 정상.
* WAF 2대 + HAProxy 앞단 이중화 후, **약 50% 확률로 지연** 발생.

### 핵심 원인(구조적)

* WAF의 `main.conf`에서 **443은 `listen 443 ssl;`(TLS 리스너)** 입니다.
* 그런데 HAProxy가 WAF로 보낼 때 `server ... :443`로 보내면서 `ssl` 옵션이 없는 형태(=평문 HTTP를 443 TLS 리스너로 전송)가 섞이면

  * TLS 핸드셰이크 미일치 → 재시도/대기/타임아웃 → **지연**
  * 로드밸런싱이 2대면 **“반반”처럼 보이는 패턴**이 흔합니다.

### 해결 방향(운영 표준)

요구사항이 “**HAProxy에서 TLS 종료** + **WAF는 평문으로 받아 분석** + **WAF→WEB은 HTTPS**” 이므로, 최종 정답은 아래입니다.

* **Client → HAProxy : HTTPS**
* **HAProxy : TLS 종료**
* **HAProxy → WAF : HTTP 80(평문)**
* **WAF → WEB : HTTPS**

추가로,

* WAF가 HAProxy 뒤에서 동작하므로 **X-Forwarded-Proto(원래 https였던 요청인지) 유지**가 중요합니다. 기존 proxy.conf는 `$scheme` 기반이라 HAProxy 뒤에서 **항상 http로 떨어질 수 있음**이 포인트였습니다. 
* 또한 **real_ip 신뢰 범위(0.0.0.0/0)는 금지**하고, HAProxy만 신뢰하도록 좁혀야 합니다. (보안/우회 방지)

---

## 2) 최종 파일 세트 다운로드

아래 압축파일에 **최종 권장 구성 파일 전체**를 담아두었습니다.

**[Download the config archive](sandbox:/mnt/data/plura_final_configs.tar.gz)**

압축 내부 구조는 다음과 같습니다.

* `haproxy/haproxy.cfg`
* `nginx/nginx.conf`
* `nginx/plura/root.conf`
* `nginx/plura/main.conf`
* `nginx/plura/portlist`
* `nginx/proxy.conf`
* `nginx/plura/xff_opt`
* `nginx/server.conf`
* `nginx/conf.d/plurawaf.conf`
* `nginx/conf.d/default.conf`

> ⚠️ `nginx/plura/main.conf`의 `<WEB_BACKEND_IP_OR_HOST>` 는 **실제 고객 WEB/L4 VIP**로 반드시 바꿔야 합니다.
> 사용자가 말씀하신 `192.168.101.121`은 “HAProxy IP”로 쓰는 전제이므로, WEB 목적지까지 `192.168.101.121`로 두면 루프 위험이 있습니다.

---

## 3) 최종 파일 내용 + 파일별 “왜 이렇게 관리해야 하는가”

아래는 압축파일과 동일한 내용입니다(붙여넣기용).

---

# A. /etc/haproxy/haproxy.cfg  *(추가 제공: 전체 구성의 핵심이라 포함)*

```cfg
# /etc/haproxy/haproxy.cfg
# -------------------------------------------------------------------
# 목적:
#  - Client(HTTPS) -> HAProxy(TLS 종료) -> PLURA-WAF(HTTP:80) -> WEB(HTTPS)
#  - WAF는 평문 HTTP로 받아 L7 분석(ModSecurity)을 수행
# -------------------------------------------------------------------

global
    log 127.0.0.1 local0
    daemon
    maxconn 8192
    nbthread 4
    stats socket /var/run/haproxy.sock mode 660 level admin expose-fd listeners

    ssl-default-bind-options ssl-min-ver TLSv1.2

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull

    timeout http-request  10s
    timeout connect       5s
    timeout client        300s
    timeout server        300s

    retries 2

frontend fe_http_80
    bind *:80
    mode http
    redirect scheme https code 301 if !{ ssl_fc }

frontend fe_https_443
    bind *:443 ssl crt-list /etc/haproxy/SSL/crt-list.txt alpn h2,http/1.1
    mode http

    option forwardfor
    http-request set-header X-Forwarded-Proto https
    http-request set-header X-Forwarded-Port  443

    default_backend be_waf_http_80

backend be_waf_http_80
    mode http
    balance roundrobin

    option httpchk GET /health
    http-check expect status 200

    # ★ 중요: WAF는 HTTP(80)로 받도록 구성해야 함
    server waf75 10.10.10.75:80 check
    server waf95 10.10.10.95:80 check

listen stats
    bind *:8888
    mode http
    stats enable
    stats uri /haproxy?stats
    # stats auth <USER>:<STRONG_PASSWORD>
```

### 왜 이렇게 관리해야 하나?

* **지연 원인 제거의 핵심**: WAF가 `listen 443 ssl;`인 상태에서 HAProxy가 평문을 443으로 보내면 지연이 발생합니다. 따라서 **WAF는 80**, HAProxy 백엔드도 **:80**이어야 합니다.
* `X-Forwarded-Proto=https`는 WAF/WEB에서 “원래 https 요청”을 유지(쿠키 Secure, 리다이렉트, 링크 생성 오류 방지).
* `/health` 헬스체크로 “살아있지만 느린 노드”를 더 빨리 분리할 수 있습니다.

---

# B. /etc/nginx/nginx.conf

```nginx
# /etc/nginx/nginx.conf
# -------------------------------------------------------------------
# 목적:
#  - Nginx(PLURA-WAF) 공통 설정
#  - http{} 안에서 plura/root.conf만 포함하여 "단일 진입점"으로 관리
# -------------------------------------------------------------------

user nginx;
worker_processes 6;
worker_rlimit_nofile 65536;

error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 2048;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" xff="$http_x_forwarded_for" '
                    'rt=$request_time urt=$upstream_response_time '
                    'ua="$upstream_addr" us="$upstream_status"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;

    types_hash_max_size 2048;
    large_client_header_buffers 4 16k;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # include /etc/nginx/conf.d/*.conf;

    include plura/root.conf;
}
```

### 왜 이렇게 관리해야 하나?

* 서버 블록을 여기저기(conf.d 등) 흩어두면 **WAF 2대 간 설정 드리프트**가 발생하기 쉽습니다. 현재도 `plura/root.conf`를 단일 진입점으로 쓰고 계셨고 , 이 방식을 “운영 표준”으로 고정하는 것이 가장 안전합니다.
* 로그에 `$upstream_addr`, `$upstream_status`를 넣으면 **지연이 WAF 내부인지/업스트림인지** 분석이 빨라집니다.

---

# C. /etc/nginx/plura/root.conf

```nginx
# /etc/nginx/plura/root.conf
# -------------------------------------------------------------------
# 목적:
#  - PLURA-WAF 공통 기능(include)과 보안 정책을 "한곳에서" 관리
#  - WAF 2대(이중화)에서 반드시 동일해야 하는 파일
# -------------------------------------------------------------------

include conf.d/plurawaf.conf;

geoip_country /usr/share/GeoIP/GeoIP.dat;

set_real_ip_from 192.168.101.121;
real_ip_header X-Forwarded-For;
real_ip_recursive on;

geo $realip_remote_addr $from_haproxy {
    default 0;
    192.168.101.121 1;
}

include plura/acl;
include plura/pathlist;
include plura/limit_req.conf;
include plura/testcookie.conf;

server_names_hash_bucket_size 256;

include plura/main.conf;
```

### 왜 이렇게 관리해야 하나?

* 기존에도 ModSecurity/룰/ACL/pathlist/limit_req 등을 root.conf에서 include 하고 계셨습니다.
  → **이 파일이 WAF 정책의 “컨트롤 타워”**입니다.
* `set_real_ip_from 192.168.101.121`로 **HAProxy만 신뢰**해야 합니다. (0.0.0.0/0은 XFF 위조로 정책 우회 위험)
* `$from_haproxy`로 **WAF는 HAProxy에서만 접근**되도록 강제(운영 표준).
  RealIP 적용 후 `$remote_addr`가 바뀌어도 `$realip_remote_addr`는 “원래 접속한 프록시 IP”라서 제어에 유리합니다.

> ⚠️ 중요: `set_real_ip_from`에는 “WAF가 실제로 보는 HAProxy의 소스 IP”를 넣어야 합니다.
> 라우팅/다중 NIC/SNAT 환경이면 값이 달라질 수 있으니, WAF에서 tcpdump로 실제 소스 IP를 확인해 맞추는 것이 안전합니다.

---

# D. /etc/nginx/plura/main.conf

```nginx
# /etc/nginx/plura/main.conf
# -------------------------------------------------------------------
# 목적:
#  - WAF 서버 블록 정의
#  - 권장 흐름: HAProxy(TLS 종료) -> WAF(HTTP:80) -> WEB(HTTPS)
#
# 주의:
#  - 아래 <WEB_BACKEND_IP_OR_HOST> 는 실제 고객 WEB/L4 VIP 로 바꿔야 합니다.
# -------------------------------------------------------------------

upstream kiha_web_https {
    server <WEB_BACKEND_IP_OR_HOST>:443;
    keepalive 32;
}

server {
    include plura/portlist;
    server_name _;

    if ($from_haproxy = 0) { return 444; }

    location = /health {
        access_log off;
        modsecurity off;
        add_header Content-Type text/plain;
        return 200 "ok\n";
    }

    location / {
        return 444;
    }

    include server.conf;
}

server {
    listen 80;
    server_name gw.kiha21.or.kr;

    if ($from_haproxy = 0) { return 444; }

    location / {
        include plura/ac_0;
        include plura/defense_0;

        proxy_pass https://kiha_web_https;
        include proxy.conf;
    }

    include server.conf;
}
```

### 왜 이렇게 관리해야 하나?

* **WAF는 80에서만(HAProxy 뒤) 동작하도록 단순화**하는 것이 가장 안정적입니다.
* default 서버(`server_name _`)를 두면

  * 예상치 못한 Host/경로가 들어왔을 때 **빠르게 차단/노이즈 제거**
  * HAProxy 헬스체크(`/health`)를 **룰 검사 없이 빠르게** 응답 가능
* `ac_0/defense_0`와 `ac_1/defense_1`처럼 분기된 정책은, 운영 중 누적되면 노드별 동작이 달라질 수 있습니다(“반반 이슈”의 토양).
  → **한 세트로 통일**하는 방식이 운영상 가장 안전합니다.

---

# E. /etc/nginx/plura/portlist

```nginx
# /etc/nginx/plura/portlist
listen 80 default_server;
listen [::]:80 default_server;
```

### 왜 이렇게 관리해야 하나?

* “기본(default) listen 정책”을 별도 파일로 빼면

  * 포트 정책 변경 시 `main.conf` 전체를 건드리지 않아도 됨
  * 여러 서버 블록에서 listen 정의가 엇갈리는 실수를 줄임

---

# F. /etc/nginx/proxy.conf

```nginx
# /etc/nginx/proxy.conf
proxy_redirect off;

proxy_set_header Host               $http_host;
proxy_set_header X-Forwarded-Host   $host;
proxy_set_header X-Forwarded-Server $host;

include plura/xff_opt;

proxy_set_header X-Forwarded-Proto  $http_x_forwarded_proto;

proxy_set_header Referer $http_referer;

proxy_pass_header Server;

proxy_http_version 1.1;
proxy_set_header Connection "";

chunked_transfer_encoding on;

proxy_connect_timeout 300;
proxy_send_timeout    300;
proxy_read_timeout    300;
send_timeout          300;

proxy_ssl_server_name on;
proxy_ssl_name        $host;
```

### 왜 이렇게 관리해야 하나?

* 기존 proxy.conf는 `X-Forwarded-Proto $scheme`이었습니다. 
  HAProxy가 TLS 종료 후 WAF로는 HTTP로 오기 때문에, `$scheme`는 **항상 http가 될 수 있습니다.**
  → 그러면 WEB에서 “원래 HTTPS 요청”을 잃고 **리다이렉트/쿠키/세션 문제가 발생**할 수 있어 `$http_x_forwarded_proto`로 고정 전달이 필요합니다.
* 또한 `proxy_http_version 1.1` + `Connection ""`는 업스트림과 keep-alive를 안정화시키는 기본 권장값입니다.

---

# G. /etc/nginx/plura/xff_opt

```nginx
# /etc/nginx/plura/xff_opt
proxy_set_header X-Forwarded-For $http_x_forwarded_for;
```

### 왜 이렇게 관리해야 하나?

* HAProxy가 이미 XFF 체인을 만들어주므로, WAF에서 `$proxy_add_x_forwarded_for`로 다시 append 하면
  RealIP 적용 이후에는 **client IP가 중복으로 들어갈 수 있습니다.**
* 운영 분석/고객사 로그/정책 기준에서 “클라이언트 IP가 깨끗하게 유지”되는 것이 훨씬 중요합니다.
  → 따라서 **그대로 전달**이 안전한 표준입니다.

---

# H. /etc/nginx/server.conf

```nginx
client_max_body_size 0;

error_page   406  /406_User.html;
location = /406_User.html {
    root   /usr/share/nginx/html;
    modsecurity off;
    internal;
}

location = /aes.min.js {
    gzip            on;
    gzip_min_length 1000;
    gzip_types      text/plain;
    root            /usr/share/nginx/html;
}
```

### 왜 이렇게 관리해야 하나?

* 기존 운영 파일을 최대한 유지하되(동작 변화 최소화) 

  * 406 차단페이지는 modsecurity off로 **재차단 방지**
  * 정적파일(예: aes.min.js) gzip 처리

> (권장) `client_max_body_size 0`은 무제한이므로, 운영 정책에 맞는 상한(예: 100m 등)을 두는 것이 안전합니다.

---

# I. /etc/nginx/conf.d/plurawaf.conf

```nginx
modsecurity on;

modsecurity_rules_file /etc/plurawaf/modsecurity.conf;
modsecurity_rules_file /etc/plurawaf/rules/plurawaf-crs;
```

### 왜 이렇게 관리해야 하나?

* PLURA 엔진/룰의 “단일 진입점”이며, root.conf에서 include 하고 계셨습니다.
* WAF 2대에서 이 파일이 다르면 **동일 요청이 한쪽만 느리거나 차단**될 수 있습니다(반반 이슈).

---

# J. /etc/nginx/conf.d/default.conf

```nginx
# 주석만 유지(기본적으로 include하지 않음)
```

### 왜 이렇게 관리해야 하나?

* nginx.conf에서 `include /etc/nginx/conf.d/*.conf;`를 실수로 켜면
  “의도치 않은 server{}”가 추가되어 **라우팅/기본서버 충돌**이 생길 수 있습니다.
* 따라서 default.conf는 **비어있는 주석 파일로 유지**하는 것이 가장 안전합니다.
  (운영은 plura/root.conf → plura/main.conf 체인으로만)

---

## 4) 적용 체크리스트(운영 반영 순서)

### 1) HAProxy 반영

* `be_waf_http_80` 백엔드가 반드시 `:80`으로 WAF에 연결되는지 확인
* 설정 검증:

  ```bash
  haproxy -c -f /etc/haproxy/haproxy.cfg
  systemctl reload haproxy
  ```

### 2) WAF(Nginx) 반영

* `<WEB_BACKEND_IP_OR_HOST>`를 실제 WEB/L4 VIP로 변경
* 설정 검증/리로드:

  ```bash
  nginx -t
  systemctl reload nginx
  ```

### 3) 헬스체크 확인

* HAProxy에서 WAF로:

  ```bash
  curl -sS http://10.10.10.75/health
  curl -sS http://10.10.10.95/health
  ```

### 4) “반반 지연” 재현 테스트(검증)

* 사용하신 bash 다운로드 테스트 스크립트를 돌렸을 때,

  * 실패/지연이 특정 WAF로만 몰리면 → 그 노드 설정/리소스 문제
  * 둘 다 정상으로 수렴하면 → 구조 문제 해결 완료

---

## 5) 꼭 지켜야 하는 운영 원칙 3가지

1. **WAF 2대의 설정 파일은 완전히 동일해야 합니다.**
   (`root.conf`, `main.conf`, `proxy.conf`, 룰/ACL/pathlist 포함)
2. **HAProxy TLS 종료 + WAF 평문 분석이면, HAProxy→WAF는 반드시 80(HTTP)**
   (443으로 보내려면 HAProxy가 `ssl`로 붙어야 하고, 그 경우 “평문 분석” 목적과 충돌)
3. **원래 HTTPS였다는 정보는 X-Forwarded-Proto로 끝까지 유지**
   (HAProxy에서 세팅 → WAF에서 그대로 WEB에 전달)

---

원하시면, 다음도 같이 드릴 수 있습니다(지금 구성 안정화에 매우 유용합니다).

* HAProxy 로그에 `Tq/Tc/Tr/Tt`(구간별 지연) 기록 포맷 추가
* WAF에서 응답 헤더에 `X-WAF-Node: waf75|waf95` 삽입(지연이 어느 노드에서 발생하는지 즉시 추적)

원하시는 방향이 있으면 그 기준으로 추가 최적화까지 정리해 드리겠습니다.
