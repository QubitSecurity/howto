# 🔍 PLURA-TI 연동을 위한 각 서비스별 API 생성 가이드

본 디렉터리는 IP 및 Hash 기반의 Threat Intelligence(TI) 평판 조회를 위한 API 연동 가이드를 정리한 문서입니다.  
주요 TI 소스별 API 호출 방법을 확인하고, 실무에 바로 적용할 수 있는 Bash/Python 예제를 함께 활용하세요.

---

## ✅ TI 조회 조합 정리

### 1) 🔐 IP 주소 평판 조회  
**조합: VirusTotal + AbuseIPDB**

- **VirusTotal**:  
  - AV 탐지 기반 악성 여부 확인  
  - ASN, 국가 위치 정보 포함  
- **AbuseIPDB**:  
  - 공격 유형별 리포트 (brute-force, scan 등)  
  - 커뮤니티 기반 실시간 평판 제공

---

### 2) 🧬 Hash 평판 조회  
**조합: VirusTotal + MalwareBazaar**

- **VirusTotal**:  
  - 다수 백신 엔진 탐지 결과  
  - 악성코드 관련 태그 및 탐지 비율 제공
- **MalwareBazaar**:  
  - 악성코드 패밀리 정보  
  - 캠페인 태그, 분석 벤더별 정보 포함  
  - 샘플 다운로드도 가능 (비밀번호: `infected`)

---

## 📁 문서 목록

| 파일명 | 설명 | 
|--------|------|
| [`virustotal.md`](./vendors/virustotal.md)      | VirusTotal API Key 발급 및 조회 방법 |
| [`abuseipdb.md`](./vendors/abuseipdb.md)      | AbuseIPDB 가입, API 호출 예시 및 주의사항 |
| [`malwarebazaar.md`](./vendors/malwarebazaar.md)  | 해시 기반 악성코드 정보 조회 및 샘플 다운로드 방법 |

---

## 💡 API 발급 필요 여부

| 서비스           | UI 표시               | 설명                  |
|------------------|------------------------|-----------------------|
| VirusTotal       | 🔲 API 키 발급 필요함     | 사용자 입력 필요         |
| AbuseIPDB        | 🔲 API 키 발급 필요함     | 사용자 입력 필요         |
| MalwareBazaar    | ❎ API 키 입력칸 없음     | API 키 없이 사용 가능     |

---
