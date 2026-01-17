## 📘 Sysmon for Linux 설치 가이드 (Ubuntu)

---

## 1. 개요

Ubuntu 환경에서 **Sysmon for Linux**는
Windows Sysmon과 유사한 개념으로 **보안 이벤트를 표준화된 형태로 수집**하여
**/var/log/syslog**에 기록합니다.

---

## 2. 지원 환경

### OS

* Ubuntu 20.04 LTS
* Ubuntu 22.04 LTS
* Ubuntu 24.04 LTS

### 필수 조건

* systemd
* eBPF + BTF 지원 커널
* root 권한
* 외부 네트워크 접근

---

## 3. 설치 절차

### 3.1 Microsoft 패키지 저장소 등록

```bash
wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb \
  -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
```

---

### 3.2 Sysmon 패키지 설치

```bash
sudo apt-get update
sudo apt-get install -y sysinternalsebpf sysmonforlinux
```

---

## 4. Sysmon 설정 파일 준비

```bash
sudo mkdir -p /etc/sysmon
sudo nano /etc/sysmon/sysmonconfig.xml
```

> ✔ PLURA / XDR 연동 시
> → **ProcessCreate, NetworkConnect 중심 구성 권장**

---

## 5. Sysmon 서비스 설치 및 기동

```bash
sudo sysmon -accepteula -i /etc/sysmon/sysmonconfig.xml
```

---

## 6. 동작 확인

### 6.1 서비스 상태

```bash
systemctl status sysmon
```

---

### 6.2 로그 확인

Ubuntu 기본 Syslog:

```bash
sudo tail -f /var/log/syslog
```

---

### 6.3 sysmonLogView 사용 (가독성 향상)

```bash
sudo tail -f /var/log/syslog | sudo /opt/sysmon/sysmonLogView -e 1
```

* `-e 1` : Process Create 이벤트만 출력

---

## 7. 운영 팁

### 7.1 설정 변경 반영

```bash
sudo sysmon -c /etc/sysmon/sysmonconfig.xml
```

---

### 7.2 이벤트 폭증 방지

* 전체 수집 ❌
* 서버/PC 역할 기반 필터링 ✅
* auditd / Sysmon **역할 분리 설계 권장**

---

## 8. 제거 방법

```bash
sudo sysmon -u
sudo apt-get remove -y sysmonforlinux sysinternalsebpf
```

---

