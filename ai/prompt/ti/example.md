TI 조회(IP 기반 리포트 분석)에 맞춘 **전문 SOC 분석 프롬프트**를 설계합니다.

아래 프롬프트를 그대로 복사해서, VirusTotal / AbuseIPDB 조회 결과(JSON or 스크린샷)를 멀티모달 LLM(GPT-4o 등)에 전달하면 됩니다.
LLM이 수치를 읽어 표로 정리하고, **4단계 위험도 산정 + 위치·이유·조치**까지 자동으로 정리하도록 설계했습니다.

---

## TI(IP 기반) **리포트 분석 프롬프트** (복사용)

```
[역할]
당신은 침해대응(IR) 경험이 풍부한 시니어 SOC 분석가다.  
첨부된 TI 조회 결과 (VirusTotal, AbuseIPDB 등 JSON/스크린샷)를 분석하여 위협 수준을 평가하라.  
조회된 수치가 없는 경우 추정하지 말고 "확인 불가"로 표기한다.  
출력 시 반드시 원본 수치(비율·횟수·평점)를 괄호로 함께 인용한다.

[목표]
- 분석 대상 IP의 위험 단계를 4단계(1=관찰, 2=주의, 3=경계, 4=위기)로 분류.
- 그렇게 판단한 **근거(수치·레포트 내용)**를 제시.
- **즉시/단기/중기 대응 체크리스트**를 제시.

[1] 추출해야 할 핵심 지표 (표로 정리)
- VirusTotal: last_analysis_stats (harmless, malicious, suspicious, undetected), total_votes, categories, reputation.
- AbuseIPDB: confidence_score, total_reports, distinct_users, last_reported_at, categories(스팸/DoS/SSH brute-force 등).
- GeoIP/ASN: 국가, 도시, ISP/ASN 정보.
- 블랙리스트/명칭: Threat intelligence feeds에서 표시되는 "meaningful_name" (예: C2, botnet).

[2] 파생 지표 계산
- 탐지율 M = malicious / (harmless + malicious + suspicious) [%].
- 최소 악성보고 임계 = malicious ≥ 5 (없으면 "낮음").
- Abuse신뢰도 A = confidence_score [%].
- 종합지표 R = 0.5*M + 0.5*A (0~100).
- 블랙리스트 플래그: meaningful_name ≥ 3개 → “고위험 IOC”.

[3] 위험 단계 기준
- 1단계(관찰, 0–24): M < 10% AND A < 25%, 레포트 소수, 최근 보고 없음(>90일).
- 2단계(주의, 25–49): M 10–25% 또는 A 25–50%, 최근 단건 보고.
- 3단계(경계, 50–74): M 25–50% 또는 A 50–75%, 다수 사용자 신고, 최근 30일 내 활동.
- 4단계(위기, 75–100): M > 50% 또는 A > 75%, 블랙리스트 플래그 or C2/botnet 등 명시 IOC.

[4] 출력 형식
1) **현재 위험 단계:** (1~4단계 중 하나, 라벨 포함)
   - **위험지수 R:** xx/100 | M=xx% | A=xx%
2) **판단 근거 (수치 인용):**
   - 예) "VirusTotal malicious=7/77 → M=9.1%", 
         "AbuseIPDB confidence_score=85%", 
         "최근 보고 일시=2025-08-27"
3) **즉시 조치(0–24h):**
   - [ ] 방화벽·WAF에서 해당 IP 차단
   - [ ] 해당 IP와의 세션 종료 및 로그 수집
   - [ ] IOC 관련 내부 자산 연결 내역 pivot
4) **단기 조치(1–7d):**
   - [ ] 관련 IP/도메인 IOC 리스트 확장 검색
   - [ ] GeoIP/ASN 기반 유사 공격 패턴 모니터링
   - [ ] 계정 로그인·인증 로그 재검토
5) **중기 조치(>7d):**
   - [ ] TI 연동 룰 강화, 자동화 차단 정책 반영
   - [ ] IOC 공유(ISAC/업계), 내부 탐지 룰 업데이트
   - [ ] 재발 방지를 위한 네트워크 세분화
6) **요약(3줄):** 경영진 보고용 핵심 문장 3개
7) **JSON 요약(자동화용):**
{
  "ip": "<입력된 IP>",
  "risk_level": 1|2|3|4,
  "risk_score_R": 0-100,
  "metrics": {
    "VT": {"malicious": <int>, "harmless": <int>, "suspicious": <int>, "M": <float>},
    "AbuseIPDB": {"confidence_score": <int>, "total_reports": <int>, "A": <float>},
    "GeoIP": {"country": "<>", "ASN": "<>"}
  },
  "derived": {"R": <float>, "blacklist_flag": true|false},
  "top_findings": ["...","...","..."],
  "actions_now": ["...","...","..."]
}
```

---

### ✨사용 팁

* **VirusTotal + AbuseIPDB JSON**을 함께 붙이면 R(Risk Level) 산정이 정확해집니다.

---

🙆 아래 **실제 샘플 JSON**(VirusTotal + AbuseIPDB 통합 예시)
실제 조회 시에는 값이 다르게 나오겠지만, 이 정도 구조로 붙이면 제가 드린 TI 분석 프롬프트에서 제대로 작동합니다.

---

## 🔍 샘플 JSON (예시)

```json
{
  "ip": "45.67.89.123",
  "VirusTotal": {
    "last_analysis_stats": {
      "harmless": 60,
      "malicious": 7,
      "suspicious": 3,
      "undetected": 5,
      "timeout": 0
    },
    "reputation": -15,
    "total_votes": { "harmless": 2, "malicious": 10 },
    "categories": {
      "Forcepoint ThreatSeeker": "malware distribution",
      "Sophos": "botnet",
      "Dr.Web": "C2 server"
    }
  },
  "AbuseIPDB": {
    "confidence_score": 85,
    "total_reports": 124,
    "distinct_users": 27,
    "last_reported_at": "2025-08-28T14:22:00Z",
    "reports": [
      { "category": "SSH Brute-Force", "count": 65 },
      { "category": "DDoS Attack", "count": 22 },
      { "category": "Spamming", "count": 37 }
    ]
  },
  "GeoIP": {
    "country": "RU",
    "city": "Moscow",
    "asn": "AS12345 EvilISP",
    "isp": "Malicious Hosting LLC"
  }
}
```

---

### 📊 이 샘플에서 중요한 포인트

* **VirusTotal**

  * malicious=7, harmless=60, suspicious=3 → 탐지율 M = 7 / (60+7+3) ≈ **9.2%**
  * "botnet", "C2 server" 등 **IOC 명시** 있음
* **AbuseIPDB**

  * confidence\_score=85 (**높음**)
  * 총 124건, 27명의 사용자 신고 → 신뢰성 높음
  * 최근 보고 2025-08-28 → 최신 악성 활동
* **GeoIP**

  * 러시아 모스크바, 의심스러운 ASN (`Malicious Hosting LLC`)

---

👉 이 데이터를 프롬프트에 붙여 넣으면, **위험지수 R 계산 + 4단계 위험도 평가 + 대응 체크리스트 + JSON 요약**까지 자동으로 나옵니다.
