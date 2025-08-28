**윈도우 서버**와 **리눅스 서버**에서 로그 용량 확인 방법은 각각 다릅니다. 운영 환경에 따라 아래 방법을 활용하시면 됩니다.

---

# 🪟 윈도우 서버 (Windows Server)

Windows는 **이벤트 로그(Event Viewer)** 와 **로그 파일 경로**를 통해 확인할 수 있습니다.

### 1) 이벤트 로그 저장소 크기 확인 (PowerShell)

```powershell
# 모든 이벤트 로그 최대 크기(MB) 확인
Get-EventLog -List | Select-Object Log, MaximumKilobytes

# 특정 로그 (예: Security) 확인
wevtutil gl Security | findstr "maxSize"
```

* `MaximumKilobytes` 값이 곧 해당 로그 파일의 최대 용량
* 기본적으로 보안(Security), 시스템(System), 응용프로그램(Application) 로그는 각각 수백 MB로 제한

### 2) 실제 로그 파일 크기 확인

Windows 이벤트 로그 파일은 기본적으로 다음 경로에 저장됩니다:

```
C:\Windows\System32\winevt\Logs\
```

→ 파일 확장자는 `.evtx`, 탐색기 또는 PowerShell에서 용량 확인 가능

```powershell
Get-ChildItem "C:\Windows\System32\winevt\Logs\" | Sort-Object Length -Descending | Select-Object Name, @{Name="SizeMB";Expression={[math]::Round($_.Length/1MB,2)}}
```

---

# 🐧 리눅스 서버 (Linux Server)

리눅스에서는 **syslog, journald, 애플리케이션 로그** 등 다양한 로그가 `/var/log` 디렉토리에 저장됩니다.

### 1) `/var/log` 디렉토리 전체 용량 확인

```bash
du -sh /var/log
```

👉 `/var/log` 폴더 전체 용량 표시

### 2) 로그별 상세 크기 확인

```bash
du -sh /var/log/*
```

👉 개별 로그 파일 용량 확인 (`messages`, `secure`, `dmesg`, `audit.log` 등)

### 3) systemd-journald 로그 크기 확인

```bash
journalctl --disk-usage
```

👉 journald(이벤트 로그 저장소)의 총 사용량 확인

### 4) 가장 큰 로그 상위 10개 찾기

```bash
du -ah /var/log | sort -rh | head -n 10
```

---

# ✅ 정리

* **윈도우 서버** → `Get-EventLog -List`, `wevtutil`, 또는 `C:\Windows\System32\winevt\Logs` 확인
* **리눅스 서버** → `du -sh /var/log`, `journalctl --disk-usage`, 로그별 크기 분석

---

