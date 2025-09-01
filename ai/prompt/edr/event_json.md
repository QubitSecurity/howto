아래는 해당 Sysmon 로그에서 `event_json` 으로 변환하기 위한 매핑 규칙 설명입니다.

---

## 📌 event\_json 매핑 규칙

### 1. risk\_level

* **규칙**: MITRE ATT\&CK 매핑 결과 + 이벤트 특성(지속성, 권한 상승 가능성 등)에 따라 1\~4 레벨 지정.
* **예시**: `레지스트리 Run Key 등록` → Persistence 기법, 보안상 주의 필요 → `risk_level: 3`.

---

### 2. technique

* **규칙**: PLURA 탐지엔진이 매핑한 MITRE ATT\&CK ID/Name을 그대로 사용.
* **출처**: UI 상단 설명(`레지스트리 실행 키/시작 폴더 [T1547.001]`)
* **예시**:

  ```json
  "technique": { "id": "T1547.001", "name": "Registry Run Keys / Start Folder" }
  ```

---

### 3. host

* **규칙**: 로그에 포함된 호스트 정보 + 채널명 + OS 타입을 표준화.
* **출처**: Sysmon 이벤트 → Provider 필드 (`Microsoft-Windows-Sysmon`) → Windows OS
* **예시**:

  ```json
  "host": {
    "computer": "daughters\\min",
    "channel": "Microsoft-Windows-Sysmon",
    "os": "windows",
    "time_created_utc": "<로그 UTC 시간>",
    "time_created_local": "<로컬 변환 시간>"
  }
  ```

---

### 4. event

* **규칙**: 세부 이벤트 필드들을 구조화.

  * `EventID` → `id`
  * `EventType` → `type`
  * `TargetObject` → `target_object`
  * `Image` → 실행 프로세스
  * `Details` → 명령 인자(Argument)들 분리 저장
  * `User` → 사용자 계정
  * `Hash` → 파일 해시
* **예시**:

  ```json
  "event": {
    "id": 13,
    "type": "SetValue",
    "target_object": "HKU\\...\\Run\\jandiapp",
    "image": "C:\\Windows\\SysWOW64\\reg.exe",
    "details": "\"C:\\Users\\min\\AppData\\Local\\JandiApp\\jandiapp.exe\" --processStart \"jandiapp.exe\"",
    "user": "daughters\\min",
    "hash": "725e80c5cc..."
  }
  ```

---

### 5. analysis

* **규칙**: 로그 해석/위험성 판단을 설명문 배열로 작성.
* **출처**: MITRE 설명 + 필드 기반 해석.
* **예시**:

  ```json
  "analysis": [
    "Sysmon EventID 13 레지스트리 값 설정 탐지.",
    "사용자 daughters\\min 환경에서 Run Key(jandiapp) 등록 확인.",
    "프로세스 reg.exe 에 의해 jandiapp.exe 자동 실행 등록.",
    "MITRE ATT&CK T1547.001(Persistence) 해당."
  ]
  ```

---

### 6. actions\_now

* **규칙**: 대응 조치 제안 (즉시/단기).
* **예시**:

  ```json
  "actions_now": [
    "해당 Run Key 등록이 정상 소프트웨어(JandiApp)인지 확인.",
    "등록된 바이너리(jandiapp.exe) 해시값을 TI(바이러스 토탈/AbuseIPDB) 조회.",
    "의심 시 Run Key 삭제 및 파일 격리."
  ]
  ```

---

✅ **정리**:

* **UI/로그 필드 → event\_json 매핑 규칙**을 정의하면, Sysmon/윈도우 로그든 auditd/리눅스 로그든 일관된 JSON 구조로 정리할 수 있습니다.
* 차이는 `host.channel` / `host.os` / `event.type` / `event.args` 부분이 OS·로그 형식별로 달라진다는 점입니다.

---
