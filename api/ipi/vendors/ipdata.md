아래는 **ipdata API Key 발급 방법**을 순서대로 자세히 정리한 내용입니다:

---

## ✅ ipdata API Key 발급 방법 (2025년 기준)

### 🔗 사이트 접속

1. 웹 브라우저에서 [https://ipdata.co/](https://ipdata.co/) 접속 → **Sign up for free** 버튼 클릭. ([IPData][1])

---

### 👤 계정 생성 또는 로그인

2. 회원가입 페이지에서 이메일·비밀번호 입력 후 가입 → 가입 완료 후 **Dashboard**로 이동
   또는 바로 [https://dashboard.ipdata.co/sign-up.html](https://dashboard.ipdata.co/sign-up.html) 에서 가입. ([ipdata][2])

---

### 🛡️ API Key 확인 위치

3. 로그인 후:

   * **문서(Quick Start)** 우측 상단 **Log In**을 누르면 예제 코드에 **본인 API Key가 자동 표시**됩니다. ([ipdata][3])
   * 대시보드에서도 발급된 **기본 API Key**를 확인·복사할 수 있습니다(가입 경로 동일). ([ipdata][2])

---

### 📄 API Key 종류

| 유형                | 설명                                                                            |
| ----------------- | ----------------------------------------------------------------------------- |
| **Free API Key**  | **일일 1,500건** 무료 제공, **비상업적 용도 전용**. 시작·테스트 용으로 적합. ([IPData][4])             |
| **Paid (유료) Key** | 상업적 사용 허용, 상향된 쿼터/기능(예: **도메인/IP 화이트리스트**, **Bulk Lookup**) 지원. ([ipdata][5]) |

> 참고: **EU 데이터 주권**이 필요한 경우 **EU 엔드포인트**(`https://eu-api.ipdata.co`)를 사용할 수 있습니다. ([ipdata][6])

---

### ✅ 확인 예시

발급된 키는 다음과 같이 보입니다:

```
API Key:
ae12bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

> **주의:** API Key는 인증 수단입니다. **외부 노출 금지**하고, 환경변수/비공개 설정으로 보관하세요.

---

## 📌 활용 팁

* **요청 방법(인증):**

  * 쿼리 파라미터: `https://api.ipdata.co?api-key=<YOUR_KEY>`
  * 헤더: `api-key: <YOUR_KEY>` ([ipdata][7], [ipdata.docs.apiary.io][8])

* **요청 한도/오류 메시지:**

  * Free: 일 1,500건 (초과 시 `403 Forbidden` + *"You have exceeded your free quota..."*). ([IPData][4], [ipdata][9])

* **보안(유료):**

  * **도메인/IP 화이트리스트**로 키 사용처를 제한(브라우저에서 키 노출 시 필수). ([ipdata][10])

* **EU 트래픽:**

  * **EU 엔드포인트** 사용 시 요청이 **EU 내(프랑크푸르트·파리·아일랜드)** 에서만 처리됩니다. ([ipdata][6])

* **대량 조회(유료):**

  * 한 번에 **최대 100개 IP**까지 **Bulk Lookup** 가능(POST 요청). ([ipdata][11])

---

[1]: https://ipdata.co/?utm_source=chatgpt.com "ipdata: IP Geolocation API | 20B+ Requests Served"
[2]: https://dashboard.ipdata.co/sign-up.html?utm_source=chatgpt.com "Sign Up"
[3]: https://docs.ipdata.co/?utm_source=chatgpt.com "Quick Start - ipdata"
[4]: https://ipdata.co/pricing.html?utm_source=chatgpt.com "ipdata Plans & Pricing"
[5]: https://docs.ipdata.co/docs/secure-your-api-key-premium?utm_source=chatgpt.com "Secure your API Key (Premium)"
[6]: https://docs.ipdata.co/reference/getting-started-with-your-api-1?utm_source=chatgpt.com "Overview"
[7]: https://docs.ipdata.co/reference/authentication?utm_source=chatgpt.com "Authentication - ipdata"
[8]: https://ipdata.docs.apiary.io/?utm_source=chatgpt.com "ipdata.co · Apiary"
[9]: https://docs.ipdata.co/docs/api-status-codes?utm_source=chatgpt.com "API Status Codes"
[10]: https://docs.ipdata.co/docs/client-side-vs-server-side?utm_source=chatgpt.com "Client-side vs Server-side"
[11]: https://docs.ipdata.co/docs/bulk-lookup?utm_source=chatgpt.com "Bulk Lookup"
