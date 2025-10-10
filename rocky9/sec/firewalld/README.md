# README — Rocky Linux 9 / 2 NIC (public + trusted) 방화벽/라우팅 설정 가이드

> 목적: **퍼블릭(public) NIC은 엄격 제어**, **프라이빗(trusted) NIC에서만 관리/운영 접속 허용**하도록 네트워크/파이어월드(firewalld)와 라우팅 우선순위를 구성합니다. HAProxy 프런트엔드 케이스(443만 오픈 + 내부 접속 IP 허용) 예시 포함.

---

## 0) 전제/용어

* NIC 매핑 예:

  * `enp7s0` → **public** (대외망)
  * `enp1s0` → **trusted** (내부망)
* 방화벽 존(Zone):

  * `public`: 최소 허용 원칙, 명시한 규칙만 허용
  * `trusted`: 내부망 신뢰/운영 용도 (기본은 `ACCEPT`, 필요 시 세분화 가능)
* 라우팅 우선순위:

  * **기본 경로(Default route)는 public NIC 사용**
  * 내부망은 **never-default = yes**로 기본 경로에서 제외

---

## 1) 인터페이스 ↔ 존(Zone) 매핑 및 라우팅 우선순위

> 아래 명령은 **영구 설정(NetworkManager)** 입니다.

```bash
# 존 매핑
nmcli connection modify enp7s0 connection.zone public
nmcli connection modify enp1s0 connection.zone trusted

# 기본 경로 설정
nmcli connection modify enp7s0 ipv4.never-default no   # public은 default route 가짐
nmcli connection modify enp1s0 ipv4.never-default yes  # trusted는 default route 제외

# 라우트 우선순위(값이 낮을수록 우선)
nmcli connection modify enp7s0 ipv4.route-metric 100
nmcli connection modify enp1s0 ipv4.route-metric 200

# 적용
nmcli connection up enp7s0
nmcli connection up enp1s0
```

> IPv6를 사용한다면 `ipv6.never-default`, `ipv6.route-metric`도 동일 컨셉으로 지정하세요.

---

## 2) firewalld 재시작 및 상태 점검

```bash
systemctl restart firewalld

# 런타임 상태 확인
firewall-cmd --zone=public  --list-all
firewall-cmd --zone=trusted --list-all

# 활성 존 및 인터페이스 매핑 확인
firewall-cmd --get-active-zones
```

---

## 3) 영구(permanent) 정책 설정

> `trusted` 존은 내부 관리망으로 **모두 허용(ACCEPT)** 을 영구 정책으로 지정합니다. 필요 시 더 촘촘하게(서비스/포트만 허용) 바꿀 수 있습니다.

```bash
# trusted 존을 영구적으로 ACCEPT
firewall-cmd --permanent --zone=trusted --set-target=ACCEPT

# public 존은 최소 허용 원칙 유지 (규칙은 아래 HAProxy 예시에서 구성)
firewall-cmd --permanent --zone=public
# ↑ 위 명령은 출력만; 실제 허용 규칙은 /etc/firewalld/zones/public.xml 로 관리 (아래 참조)

# 반영
firewall-cmd --reload
```

> **중요**: `/etc/firewalld/zones/` 아래에는 **영구 설정을 변경한 존만** XML이 생성됩니다.
> 기본 템플릿은 `/usr/lib/firewalld/zones/` 에 있습니다.

---

## 4) HAProxy 프런트엔드 케이스 (권장 예시)

요구사항:

1. **대외 서비스는 HTTPS(443)만 오픈**
2. 내부 운영 접속은 **IP 허용목록(allow-list)** 으로 제한
3. (옵션) VRRP/Keepalived 사용하는 경우 **`protocol vrrp` 허용**

### 4.1 `public.xml` (예시)

> 위치: `/etc/firewalld/zones/public.xml`
> 파일이 없다면 새로 생성하세요. 생성 후 `firewall-cmd --reload`.

```xml
<?xml version="1.0" encoding="utf-8"?>
<zone>
  <short>Public</short>
  <description>For use in public areas. You do not trust the other computers on networks to not harm your computer. Only selected incoming connections are accepted.</description>

  <!-- (옵션) HA 클러스터링용 VRRP 허용 -->
  <protocol value="vrrp"/>

  <!-- 내부/운영 IP 허용목록 + 443만 허용 -->
  <rule family="ipv4">
    <source address="1.1.1.1/32"/>
    <port port="443" protocol="tcp"/>
    <accept/>
  </rule>
  <rule family="ipv4">
    <source address="1.1.1.2/32"/>
    <port port="443" protocol="tcp"/>
    <accept/>
  </rule>
  <rule family="ipv4">
    <source address="1.1.1.3/32"/>
    <port port="443" protocol="tcp"/>
    <accept/>
  </rule>

  <!-- (선택) 포워딩 정책 선언: 필요 시 유지 -->
  <forward/>
</zone>
```

적용:

```bash
firewall-cmd --reload
firewall-cmd --zone=public --list-all
```

> **주의**: 443 외 포트는 허용하지 않았으므로 기본 차단됩니다.
> 외부에서 443 접근은 **지정한 소스 IP** 로만 허용됩니다.

---

## 5) 동작 검증

### 5.1 존/인터페이스/정책

```bash
firewall-cmd --get-active-zones
firewall-cmd --zone=public  --list-all
firewall-cmd --zone=trusted --list-all
```

### 5.2 라우팅/게이트웨이

```bash
ip route
nmcli -g connection.id,connection.zone connection show
```

* 기본 경로가 **public NIC (enp7s0)**을 통해 나가야 합니다.
* trusted NIC는 기본 경로에 사용되지 않습니다.

### 5.3 포트 테스트

* 외부망에서:

  ```bash
  nmap -Pn -p 443 <PUBLIC_IP>
  # → 결과가 "filtered" 또는 "open" (허용된 소스 IP에서만 open) 이어야 함
  ```
* 내부망에서:

  ```bash
  curl -I https://<PUBLIC_IP>    # 허용 IP에서 200/3xx 기대
  ```

---

## 6) 운영 팁

* **런타임 ↔ 영구 동기화**

  ```bash
  firewall-cmd --runtime-to-permanent
  firewall-cmd --reload
  ```
* **세분화된 trusted 보안**(선택): `trusted`를 기본 ACCEPT 대신 최소 허용 원칙으로 전환하려면

  ```bash
  firewall-cmd --permanent --zone=trusted --set-target=default
  firewall-cmd --permanent --zone=trusted --add-service=ssh
  firewall-cmd --reload
  ```
* **NAT 게이트웨이로도 쓰는 경우**(해당 시):

  ```bash
  sysctl -w net.ipv4.ip_forward=1
  echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-ip-forward.conf
  firewall-cmd --permanent --zone=public --add-masquerade
  firewall-cmd --reload
  ```
* **컨테이너/가상화**: Docker/Podman/CNI는 자체 iptables/nft 체인을 만듭니다. 서비스 공개 범위가 firewalld 정책을 우회하지 않도록 네트워킹 모드를 점검하세요.

---

## 7) 롤백/복구

* 특정 변경 취소:

  ```bash
  # 예: enp1s0의 존 매핑 원복
  nmcli connection modify enp1s0 connection.zone --        # (기본값으로)
  nmcli connection up enp1s0
  ```
* public.xml 잠시 비활성화(백업 후 제거):

  ```bash
  cp /etc/firewalld/zones/public.xml /root/public.xml.bak
  rm -f /etc/firewalld/zones/public.xml
  firewall-cmd --reload
  ```

  (이 경우 public 존은 `/usr/lib/firewalld/zones/public.xml` 기본 템플릿 사용)

---

## 8) 체크리스트

* [ ] `enp7s0 → public`, `enp1s0 → trusted` 매핑됨
* [ ] default route는 `enp7s0`(public)
* [ ] `public.xml`에 443 + 내부 허용 IP만 명시
* [ ] `trusted`는 내부 운영 접속 OK (ACCEPT 또는 최소 허용 정책)
* [ ] `firewall-cmd --reload` 후 상태 확인 완료
* [ ] (옵션) VRRP 사용 시 `protocol vrrp` 허용됨

---

## 부록) 자주 쓰는 점검 명령 모음

```bash
# 인터페이스/존
firewall-cmd --get-active-zones
nmcli -g connection.id,connection.zone connection show

# 존 상세
firewall-cmd --zone=public  --list-all
firewall-cmd --zone=trusted --list-all
firewall-cmd --permanent --zone=public  --list-all
firewall-cmd --permanent --zone=trusted --list-all

# 라우팅
ip route
nmcli -f ipv4.method,ipv4.never-default,ipv4.route-metric connection show enp7s0
nmcli -f ipv4.method,ipv4.never-default,ipv4.route-metric connection show enp1s0

# 규칙 적용
firewall-cmd --reload
firewall-cmd --runtime-to-permanent
```

---

### 끝.
