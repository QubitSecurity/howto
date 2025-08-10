# PLURA Sysmon 자동 설치 스크립트

## 개요
이 스크립트는 **PLURA EDR 에이전트**가 **시스템 권한**으로 실행되어,  
Sysmon을 자동으로 설치하거나 구성 업데이트를 수행합니다.  
실행 결과와 오류 원인은 **Windows 이벤트 로그(Application)**에 기록됩니다.

---

## 동작 요약

`C:\Program Files\PLURA\sysmon64.exe` (또는 `sysmon.exe`)와 `sysmon-plura.xml`이 존재하면 다음과 같이 동작합니다.

1. **미설치 시**
   - 명령어:  
     ```powershell
     sysmon64.exe -accepteula -i "C:\Program Files\PLURA\sysmon-plura.xml"
     ```
   - Sysmon을 설치하고, **설치된 서비스 이름**과 **파일 버전**을 Application 로그에 기록합니다.

2. **기설치 시**
   - 명령어:  
     ```powershell
     sysmon64.exe -accepteula -c "C:\Program Files\PLURA\sysmon-plura.xml"
     ```
   - 기존 Sysmon 구성 파일을 업데이트하고, **현재 실행 파일의 버전**을 Application 로그에 기록합니다.

3. **실패 시**
   - Application 로그에 다음 정보를 모두 기록하여 원인 분석이 가능하도록 합니다:
     - ExitCode
     - StdOut
     - StdErr
     - 실행 커맨드

---

## 이벤트 로그

- **이벤트 소스**: Windows 기본 `Application`
- **로그 위치**: Windows 이벤트 뷰어 → **Windows 로그** → **Application**

---

## 사용 환경

- 실행 권한: **SYSTEM 권한**
- 파일 경로:
  - Sysmon 실행 파일:  
    `C:\Program Files\PLURA\sysmon64.exe` (64비트 OS)  
    `C:\Program Files\PLURA\sysmon.exe` (32비트 OS)
  - Sysmon 설정 파일:  
    `C:\Program Files\PLURA\sysmon-plura.xml`

---
