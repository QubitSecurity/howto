Rocky Linux 9 기준으로 **nginx 최신(mainline) 패키지** 설치 방법을 정리했습니다.  
공식 저장소(nginx.org) 사용, **GPG 서명 검증(gpgcheck=1, repo_gpgcheck=1)** 권장 설정과 **GPG 키 등록**까지 포함합니다.  
(Rocky 9은 모듈 스트림이 없으므로 `dnf module …` 단계가 필요 없습니다.)

---

# Nginx (Rocky Linux 9 — mainline + GPG 검증)

## 0. Preconfig

### 0.1 nginx 공식 GPG 키 등록

```bash
sudo rpm --import https://nginx.org/keys/nginx_signing.key
```

### 0.2 nginx.repo 생성

```bash
sudo vi /etc/yum.repos.d/nginx.repo
```

```ini
[nginx-mainline]
name=nginx mainline repo
baseurl=https://nginx.org/packages/mainline/rhel/9/$basearch/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://nginx.org/keys/nginx_signing.key
# Rocky/RHEL 기본 저장소보다 우선 적용하고 싶다면(선택)
# priority=9
```

> 참고
>
> * `gpgcheck=1`: 패키지 서명 검증
> * `repo_gpgcheck=1`: 리포지토리 메타데이터 서명 검증
> * `gpgkey`: 검증에 사용할 공개키 경로
> * `priority`는 `dnf-plugins-core` 설치 후 동작하며, 충돌을 방지해 **nginx.org 패키지를 우선** 쓰고 싶을 때만 설정하세요.

(선택) priority 사용 시:

```bash
sudo dnf -y install dnf-plugins-core
```

### 0.3 캐시 정리

```bash
sudo dnf clean all
sudo dnf makecache
```

---

## 1. Install

### 1.1 nginx 설치

```bash
sudo dnf -y install nginx
```

### 1.2(선택) 작업 디렉토리 준비

```bash
su - username
mkdir -p ~/cdn ~/repo
```

### 1.3 nginx 기동 및 자동시작

```bash
sudo systemctl enable --now nginx
sudo systemctl status nginx --no-pager
```

### 1.4 firewalld 규칙 등록

```bash
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --add-service=https --permanent
sudo firewall-cmd --reload
```

---

## 2. Stream(TCP/UDP 프록시) 사용하기

> **중요:** nginx.org의 메인라인 패키지는 `--with-stream`이 포함되어 있어 **소스 컴파일이 필요 없습니다.**
> `stream {}` 블록만 설정하면 됩니다.

### 2.1 예시: syslog TCP/UDP(514) 프록시

```nginx
# /etc/nginx/nginx.conf (혹은 /etc/nginx/conf.d/stream.conf)
stream {
    # TCP 514
    server {
        listen 514;
        proxy_pass 10.0.0.10:514;
    }
    # UDP 514
    server {
        listen 514 udp;
        proxy_pass 10.0.0.10:514;
    }
}
```

검증 및 재시작:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

방화벽(필요 시):

```bash
sudo firewall-cmd --permanent --zone=public --add-port=514/tcp
sudo firewall-cmd --permanent --zone=public --add-port=514/udp
sudo firewall-cmd --reload
```

---

## 3. SELinux

정적 파일 서빙(예: `/home/users/…`)이나 **업스트림 프록시**를 할 때 추가 설정이 필요할 수 있습니다.

### 3.1 콘텐츠 라벨링

```bash
# 예: /home/users 아래 정적 파일 제공
sudo chmod -R 755 /home
sudo chcon -R -t httpd_sys_content_t /home/users/
```

### 3.2 프록시/아웃바운드 연결 허용(필요 시)

```bash
# nginx가 백엔드로 TCP 연결(proxy_pass 등) 가능하도록
sudo setsebool -P httpd_can_network_connect 1
```

---

## 4. X-Forwarded-For Header Validation

### 4.1 proxy_set_header 예시

```nginx
http {
    server {
        listen 80;

        location / {
            proxy_pass http://upstream_server;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
```

> **보안 팁**
>
> * 신뢰 가능한 프록시 체인만을 허용하려면 `real_ip_header X-Forwarded-For;`, `set_real_ip_from <CIDR>;` 조합으로 **원 IP 신뢰 대역**을 제한하세요.
> * 필요 시 `map`을 이용해 `X-Forwarded-For` 유효성 검사를 추가하거나, WAF/리버스 프록시(HAProxy 등)에서 전처리해 위·변조를 차단하세요.

---

## (참고) Rocky 8 문서와의 차이점 요약

* **저장소 경로**: `centos/8` → **`rhel/9`**
* **모듈 스트림**: Rocky 9에는 **nginx 모듈 스트림이 없음** → `dnf module …` 단계 생략
* **보안 검증 강화**: `gpgcheck=1` + **`repo_gpgcheck=1`** + GPG 키 사전 등록 명시
* **Stream 기능**: 패키지에 기본 포함 → **소스 컴파일 불필요** (설정만 추가)

필요하시면 `real_ip` 보강 템플릿이나 `stream`을 이용한 TCP/UDP 로드밸런싱 샘플도 추가로 드릴게요.
