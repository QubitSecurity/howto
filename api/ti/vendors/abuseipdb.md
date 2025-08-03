아래는 **AbuseIPDB API Key 발급 방법**을 단계별로 정리한 설명입니다.

---

## ✅ AbuseIPDB API Key 발급 방법

### 🔗 1. AbuseIPDB 사이트 접속

* URL: [https://www.abuseipdb.com/](https://www.abuseipdb.com/)

---

### 👤 2. 회원 가입 또는 로그인

* 우측 상단의 **\[Register]** 또는 **\[Sign in]** 클릭
* 이메일 기반 계정 생성 필요 (소셜 로그인 미지원)
* 로그인 후 대시보드 접근 가능

---

### 🛠️ 3. API Key 발급 위치

* 로그인 후, 상단 메뉴에서
  **\[Account] → \[API]** 또는 직접 링크:
  [https://www.abuseipdb.com/account/api](https://www.abuseipdb.com/account/api)

---

### 📄 4. API Key 종류 및 제한

| 항목                 | 내용                                   |
| ------------------ | ------------------------------------ |
| **Free Tier (기본)** | ✔️ 1분당 최대 20회 요청 가능                  |
| **Premium**        | ✔️ 추가 요청 수 / 대량 리포트 / Export 기능 등 제공 |
| **제공 형식**          | 80\~90자 길이의 랜덤 문자열 API 키             |

예시:

```
Key:
z3f89aa6f57cf58c62b78bcbfa4e79e22dc43f676c839364a5e1fda4d2d6d969
```

---

### ⚠️ API 사용 시 주의사항

* 헤더에 `"Key: <YOUR_API_KEY>"` 형식으로 포함해야 함
* AbuseIPDB는 **보고(report)** 기능도 있지만, 평판 조회만 사용할 수도 있음
* 사용량 초과 시 429 HTTP 응답 발생

---

### ✅ 빠른 테스트 예시 (Bash)

```bash
curl -G https://api.abuseipdb.com/api/v2/check \
  --data-urlencode "ipAddress=8.8.8.8" \
  -H "Key: <YOUR_API_KEY>" \
  -H "Accept: application/json"
```

---

## 📌 요약

| 항목      | 설명                                                                             |
| ------- | ------------------------------------------------------------------------------ |
| 사이트     | [https://www.abuseipdb.com/](https://www.abuseipdb.com/)                       |
| API 페이지 | [https://www.abuseipdb.com/account/api](https://www.abuseipdb.com/account/api) |
| 무료 제한   | 1분당 20건 요청                                                                     |
| 필요 정보   | 이메일 계정 가입 후 로그인                                                                |

---
