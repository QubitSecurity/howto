# 분석 대상: 45.67.89.123

## 1) **현재 위험 단계:** 4단계(위기)

* **위험지수 R:** **48/100** | **M=10.0%** | **A=85%**

> 판정 로직: A(AbuseIPDB 신뢰도)가 \*\*75% 초과(85%)\*\*이므로 4단계 충족. 또한 TI 카테고리에서 \*\*의미있는 명칭 3개(botnet, C2, malware distribution)\*\*로 **블랙리스트 플래그** 조건 충족.

---

## 2) 핵심 지표 (표)

### VirusTotal

| 지표                            | 값                                                                                            |
| ----------------------------- | -------------------------------------------------------------------------------------------- |
| last\_analysis\_stats         | harmless **60**, malicious **7**, suspicious **3**, undetected **5**, timeout **0**          |
| total\_votes                  | harmless **2**, malicious **10**                                                             |
| reputation                    | **-15**                                                                                      |
| categories (meaningful\_name) | Forcepoint ThreatSeeker: **malware distribution**, Sophos: **botnet**, Dr.Web: **C2 server** |

### AbuseIPDB

| 지표                 | 값                                                           |
| ------------------ | ----------------------------------------------------------- |
| confidence\_score  | **85**                                                      |
| total\_reports     | **124**                                                     |
| distinct\_users    | **27**                                                      |
| last\_reported\_at | **2025-08-28T14:22:00Z**                                    |
| categories(요약)     | SSH Brute-Force **65**, DDoS Attack **22**, Spamming **37** |

### GeoIP / ASN

| 지표             | 값                                           |
| -------------- | ------------------------------------------- |
| country / city | **RU / Moscow**                             |
| ASN / ISP      | **AS12345 EvilISP / Malicious Hosting LLC** |

### 블랙리스트 / 명칭(meaningful\_name)

| 지표          | 값                                                |
| ----------- | ------------------------------------------------ |
| 명칭 수        | **3개** (malware distribution, botnet, C2 server) |
| 고위험 IOC 플래그 | **충족** (≥3개)                                     |

---

## 3) 파생 지표 계산

* **탐지율 M** = malicious / (harmless + malicious + suspicious)
  \= **7 / (60+7+3) = 7 / 70 = 10.0%**
* **최소 악성보고 임계**: malicious ≥ 5 → **충족 (7 ≥ 5)**
* **Abuse 신뢰도 A** = **85%**
* **종합지표 R** = 0.5·M + 0.5·A = 0.5·10.0 + 0.5·85 = **47.5 → 48/100**
* **블랙리스트 플래그**: meaningful\_name **3개** → **고위험 IOC**

---

## 4) **판단 근거 (수치 인용)**

* **VirusTotal**: malicious **7/70** → **M=10.0%**, 최소 악성보고 임계 **충족(7≥5)**, reputation **-15**, total\_votes **malicious 10 vs harmless 2**.
* **AbuseIPDB**: confidence\_score **85%**, total\_reports **124**, distinct\_users **27**, **최근 보고(2025-08-28)** → **최근 30일 내 활동**.
* **블랙리스트/명칭**: **botnet/C2/malware distribution (3개)** → **고위험 IOC 조건 충족**.
* **GeoIP/ASN**: **RU/Moscow**, **AS12345 EvilISP / Malicious Hosting LLC** (호스팅 자원에서의 대량 악성 행위 지표와 결합 시 위험도 상승).

결론적으로, **A=85%** 및 **의미있는 명칭 3개**로 4단계(위기) 요건에 해당.

---

## 5) 대응 체크리스트

### **즉시 조치 (0–24h)**

* [ ] **방화벽·WAF에서 해당 IP 차단** (정책 기록 남김)
* [ ] **해당 IP와의 활성 세션 즉시 종료** 및 **네트워크/웹/시스템 로그 수집** (원본·무결성 보존)
* [ ] **IOC 피벗**: 동일 ASN/대역(AS12345), 동일 카테고리(botnet/C2) 연관 IP/도메인 신속 탐색
* [ ] 인증/관리 포트(SSH/RDP/패널) 접근 IP 화이트리스트 일시 강화

### **단기 조치 (1–7d)**

* [ ] **연관 IOC 확장**: VT/AbuseIPDB에서 **공유 리포트·코멘트·공유 해시** 기반 주변 IOC 크롤링
* [ ] **GeoIP/ASN 기반 룰**: RU/HOSTING 구간 **임시 강화 룰**(폭주 방어·속도 제한·행위 기반 차단)
* [ ] **계정 보안 점검**: SSH 브루트포스 흔적(로그인 실패 패턴)·관리자 계정 잠금정책·MFA 재점검
* [ ] **웹 애플리케이션**: 로그인·게시·업로드 엔드포인트 레이트리밋/캡차 점검

### **중기 조치 (>7d)**

* [ ] **TI 연동 룰 고도화**: **A(Abuse)·M(VT)** 가중 합성 **R 임계치 자동 차단**(예: R≥40)
* [ ] **IOC 공유/협업**: ISAC/업계 공유, 내부 탐지 룰·대응 플레이북 업데이트
* [ ] **네트워크 세분화/제로트러스트**: 관리망·DB망 분리, 동서 트래픽 마이크로세그멘테이션
* [ ] **비정상 인증 탐지 EDR/SIEM 시나리오**: 실패율 급증·국가 이동·ASN 변경 감지 룰 상시화

---

## 6) **요약(3줄, 경영진 보고용)**

1. 해당 IP는 **AbuseIPDB 신뢰도 85%** 및 **botnet/C2 명시**로 **4단계(위기)** 분류됨.
2. **최근 30일 내 활동(2025-08-28)**, 다수 사용자 신고 **124건/27명**으로 공격 지속 가능성 높음.
3. 즉시 차단·로그 보존 후, **ASN/국가 기반 확장 차단**과 **인증·웹 엔드포인트 방어 강화** 필요.

---

## 7) **JSON 요약(자동화용)**

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

### 메모

* 실제 분석 시에는 **당일자 최신 결과**를 붙여주세요. 숫자 미존재 항목은 “확인 불가”로 남겨야 하며, 임의 추정은 금지합니다.
* 동일 ASN/대역 및 동일 의미 명칭(botnet/C2) IOC는 **우선 순위 상향** 대상입니다.
