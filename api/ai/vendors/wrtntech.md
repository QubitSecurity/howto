다음은 **Wrtn Tech (Wrtn Technologies / Wrtn.ai)** 서비스의 API Key 또는 Prompt API 사용 안내 문서입니다.

---

## ✅ Wrtn Tech (Wrtn.ai) API 키 또는 Prompt API 사용 방법 (2025년 기준)

### 🔗 서비스 접속 및 정보 확인

1. 웹 브라우저에서 [https://wrtn.io](https://wrtn.io) 또는 Wrtn Technologies 공식 홈페이지에 접속 ([wrtn.io][1])
2. Wrtn 플랫폼은 한국과 일본에서 사용자 중심의 AI “슈퍼앱”으로, 채팅·문서 편집·감정 대화 에이전트 등을 제공 중 ([Microsoft][2], [wrtn.io][1])

---

### 👤 계정 로그인 or 가입

* Wrtn 서비스 이용을 위해 계정이 필요합니다.
* GitHub나 이메일, 기타 SNS 계정으로 가입 또는 로그인 가능.

---

### 🛠️ Wrtn의 API 접근 방식

* Wrtn.ai는 OpenAI 스타일의 **비공식 JSON‑based API**를 통해 Wrtn 플랫폼과 연동하거나 프롬프트를 전송할 수 있습니다 ([GitHub][3], [wrtn.io][1])
* Python 기반 wrapper 라이브러리(`wrtn_python`)의 형태로 제공되며, 대화 메시지를 JSON 포맷으로 Wrtn 서버에 POST 형태로 송신하는 방식입니다 ([GitHub][3])

---

### 🔑 인증 정보 구성

* `wrtn.json` 파일에 다음 필드를 포함해 인증 정보를 구성

  ```json
  [
    {
      "id": "name@example.com",
      "pw": "your_password",
      "key": "eyJ…refresh…"
    }
  ]
  ```

  * `id`: Wrtn 계정 이메일 또는 사용자 ID
  * `pw`: Wrtn 계정 비밀번호
  * `key`: 서버에서 발급받은 **Access Key** 또는 **Refresh Key** 형태의 문자열 ([GitHub][3], [AltexSoft][4])
* 라이브러리가 자동으로 `id`와 `pw`로 로그인한 후 `refresh_key`를 갱신하며 `key` 필드에 저장합니다 ([GitHub][3])

---

### 📡 API 요청 예시

* 기본 요청 구조:

  ```json
  {
    "messages":[
      {"role": "system", "content": "system prompt"},
      {"role": "user",   "content": "your prompt"}
    ],
    "model":"gpt-4"
  }
  ```
* HTTP POST 방식으로 Wrtn의 프록시 서버(예: `localhost:41323`)에 전송 가능하며, GPT-4 스타일 JSON 포맷과 호환됩니다 ([GitHub][3])
* Streaming 모드를 활성화할 수도 있으며, SillyTavern 등의 클라이언트와도 통합해 사용할 수 있습니다 ([GitHub][3])

---

## ⚠️ 주의사항 및 권장 항목

* **비공식 API**이므로 Wrtn 측 정책 변경 시 동작이 불안정해질 수 있음
* `wrtn.json`에 있는 인증 정보는 **절대로 외부에 공개되지 않도록 주의**

  * `.gitignore`, 환경 변수, 안전한 암호 저장 방법 추천 ([GitHub][3], [Reddit][5])
* 서버가 검열 정책, 사용량 제한 등으로 오류를 반환할 수 있으며, 그 원인을 Wrtn 서버 변경으로 볼 수 있습니다 ([GitHub][3])

---

## 📌 요약 테이블

| 항목        | 설명                                                     |
| --------- | ------------------------------------------------------ |
| 인증 방식     | `wrtn.json` 내 사용자ID/비밀번호/키 (비공식 JSON 방식 인증)            |
| API 호출 구조 | OpenAI‑호환 메시지 JSON + `model`: `"gpt‑4"` 등 지정           |
| 요청 방식     | POST to 프록시 서버 (예: `localhost:41323`) 또는 Wrtn endpoint |
| 키 관리 방식   | 자동 갱신된 `refresh_key` 사용, 안전한 저장 권장                     |

---

주석

[1]: https://wrtn.io/en/?utm_source=chatgpt.com "WRTN Technologies"
[2]: https://www.microsoft.com/en/customers/story/20597-wrtn-azure?utm_source=chatgpt.com "Wrtn rewrites the next generation of its consumer-enabling superapp ..."
[3]: https://github.com/cannonLCK/wrtn_python?utm_source=chatgpt.com "cannonLCK/wrtn_python: Wrtn.ai unofficial openai-style api - GitHub"
[4]: https://www.altexsoft.com/blog/api-documentation/?utm_source=chatgpt.com "How to Write API Documentation: Best Practices and Examples"
[5]: https://www.reddit.com/r/learnpython/comments/15zmfwn/storeuse_api_keys_without_having_them_actually/?utm_source=chatgpt.com "Store/use API Keys without having them actually written in plaintext ..."
