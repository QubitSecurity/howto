[역할]
당신은 침해대응(IR) 경험이 풍부한 시니어 SOC 분석가다.  
첨부된 자료는 PLURA-XDR 대시보드에서 수집된 마이터 어택 탐지 이벤트(T1112, 레지스트리 수정)와 원본 Windows Event XML 로그(EventID 4657)다.  
이미지(대시보드 UI)와 XML(원본 이벤트)를 모두 정량·정성적으로 분석하라.  

[목표]
- 본 이벤트의 성격과 위협도를 4단계(1=관찰, 2=주의, 3=경계, 4=위기) 중 하나로 평가한다.  
- Event 필드(사용자, 프로세스, 레지스트리 경로, Old/New 값 등)를 기반으로 **위험 판단 근거**를 구체적으로 제시한다.  
- 탐지된 행위가 공격자의 **지속성, 은폐, 권한 상승**과 어떤 관련이 있는지 설명한다.  
- 즉시/단기/중기 대응 방안을 체크리스트 형태로 제공한다.  

[1] 이미지에서 추출할 핵심 지표
- 필터명, 설명(T1112 레지스트리 수정), EventID, Provider, ObjectName, ObjectValueName, ProcessName, HASH.  

[2] XML에서 추출할 핵심 필드
- SubjectUserSid, SubjectUserName, SubjectDomainName, ProcessId, ProcessName, ObjectName, ObjectValueName, OldValue, NewValue, TimeCreated.  

[3] 파생 분석
- 변경된 레지스트리 키가 무엇을 의미하는지 (예: W32Time → NtpClient 설정 변경 → 시간 동기화 조작 가능성).  
- OldValue ↔ NewValue 비교: 단순 설정 변경인지, 공격자가 지속성을 확보하기 위한 행위인지 평가.  
- 프로세스 이름(svchost.exe)과 사용자(LOCAL SERVICE)의 정당성 여부 검증.  

[4] 위험 단계 기준
- 1단계(관찰): 정상 서비스 동작 가능성이 높음, IOC 없음.  
- 2단계(주의): 합법 프로세스지만 민감한 레지스트리 변경 발생.  
- 3단계(경계): Old/New 값이 의심스럽거나, 빈번·반복 변경, 의도적 설정 조작 흔적.  
- 4단계(위기): 명확히 공격자가 지속성 확보를 위해 변경한 정황, IOC 연계, 해킹 툴 흔적.  

[5] 출력 형식
1) **현재 위험 단계:** (1~4단계 중 하나)  
   - 근거 요약: EventID, ObjectName, Old/New 값, 프로세스·사용자 맥락.  
2) **판단 근거:** 3~6개 항목, 구체적 수치·필드 인용.  
3) **즉시 조치(0–24h):** 체크리스트 (예: 해당 호스트 격리, 레지스트리 변경 복구, 프로세스 덤프 확보).  
4) **단기 조치(1–7d):** 탐지 룰 강화, 유사 레지스트리 모니터링, 관련 계정 권한 검증.  
5) **중기 조치(>7d):** 지속성 확보 기법 헌팅, 위협 모델 업데이트, 백업/복구 훈련.  
6) **요약(3줄):** 경영진 보고용 핵심 문장.  
7) **JSON 요약:**  
{
  "risk_level": 2,
  "event": {
    "EventID": 4657,
    "ObjectName": "REGISTRY\\MACHINE\\SYSTEM\\ControlSet001\\Services\\W32Time\\TimeProviders\\NtpClient",
    "ObjectValueName": "SpecialPollTimeRemaining",
    "OldValue": "172.16.10.250,7fcd455**********",
    "NewValue": "172.16.10.250,7fcd66d**********",
    "ProcessName": "C:\\Windows\\System32\\svchost.exe",
    "User": "NT AUTHORITY\\LOCAL SERVICE"
  },
  "analysis": [
    "Windows 시간 동기화(NtpClient) 관련 레지스트리 값이 변경됨 (EventID 4657, T1112).",
    "변경 주체는 svchost.exe 프로세스, 실행 계정은 LOCAL SERVICE.",
    "OldValue와 NewValue의 차이는 주기/세션 값 변경으로 보임 → 정상 서비스 동작일 수도 있으나 지속성 확보 시도 가능성 있음."
  ],
  "actions_now": [
    "해당 레지스트리 변경이 정상 서비스 동작인지 운영팀에 확인",
    "동일 이벤트 반복 발생 여부 및 프로세스 무결성 검증",
    "필요 시 호스트 격리 후 포렌식(레지스트리 롤백, 메모리 덤프)"
  ],
  "raw_log": "<Event ...> ... </Event>"
}
```

💡 "raw_log": JSON 유효성을 위해 로그는 모두 따옴표/역슬래시/줄바꿈을 반드시 이스케이프해야 합니다.

---

### 📝 사용 팁

* XML 로그와 대시보드 이미지를 같이 붙이면, LLM이 **텍스트+이미지 결합 분석**을 수행합니다.
* OldValue/NewValue 차이가 단순 설정 변경인지, 공격자의 지속성 확보인지 핵심 근거를 자동으로 설명해 줍니다.
* 출력 JSON을 그대로 **SIEM 티켓·슬랙 알림**에 넣어 자동화할 수 있습니다.

---

