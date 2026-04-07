## 📘 Sysmon for Linux 설치 가이드 (RHEL)

## 1. 개요

**Sysmon for Linux**는 Microsoft Sysinternals에서 제공하는 보안 이벤트 수집 도구로,
RHEL 환경에서 **프로세스 생성, 네트워크 연결, 파일 활동** 등의 이벤트를 **eBPF 기반**으로 수집하여 **Syslog**로 출력합니다.

> ⚠️ auditd 대체제가 아니라 **보완재**이며, EDR / XDR / SIEM 연계를 전제로 사용합니다.

---

## 2. 지원 환경

### OS

* RHEL 8.x / 9.x
* Rocky Linux 8.x / 9.x
* AlmaLinux 8.x / 9.x

### 필수 조건

* `systemd` 사용
* eBPF + BTF 지원 커널
* root 권한
* 외부 네트워크 접근 가능 (`packages.microsoft.com`)

---

## 3. 설치 절차

### 3.1 Microsoft 패키지 저장소 등록

```bash
sudo rpm -Uvh https://packages.microsoft.com/config/rhel/$(. /etc/os-release && echo ${VERSION_ID%%.*})/packages-microsoft-prod.rpm
```

---

### 3.2 Sysmon 패키지 설치

```bash
sudo dnf install -y sysinternalsebpf sysmonforlinux
```

설치되는 주요 구성 요소:

* `sysmon` : Sysmon 실행 파일
* `sysinternalsebpf` : eBPF 런타임 지원

---

## 4. Sysmon 설정 파일 준비

### 4.1 설정 디렉터리 생성

```bash
sudo mkdir -p /etc/sysmon
```

### 4.2 설정 파일 작성

```bash
sudo vi /etc/sysmon/sysmonconfig.xml
```

> ✔ 운영 환경에서는 **collect-all 설정을 절대 권장하지 않습니다**
> → 이벤트 폭증 + 성능 저하 발생 가능

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

RHEL 계열 기본 로그 위치:

```bash
sudo tail -f /var/log/messages
```

또는 journald 기반 확인:

```bash
sudo journalctl -u sysmon -f
```

---

## 7. 운영 팁 (중요)

### 7.1 설정 변경 적용

```bash
sudo sysmon -c /etc/sysmon/sysmonconfig.xml
```

---

### 7.2 Syslog 메시지 잘림 방지

Sysmon 이벤트는 XML 형태이며,
Syslog 기본 설정에서는 **8KB 이상 메시지가 잘릴 수 있음**

```xml
<FieldSizes>CommandLine:50,Image:50</FieldSizes>
```

---

## 8. 제거 방법

```bash
sudo sysmon -u
sudo dnf remove -y sysmonforlinux sysinternalsebpf
```

---
