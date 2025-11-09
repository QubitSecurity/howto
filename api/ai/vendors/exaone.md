다음은 **LG EXAONE** 서비스의 API Key 발급 방법을 사용자에게 안내하기 위한 문서입니다.

---

## ✅ EXAONE API Key 발급 방법 (2025년 기준)

### 🔗 사이트 접속

1. 웹 브라우저에서 **FriendliAI 콘솔** 접속: [https://friendli.ai](https://friendli.ai) → **Serverless Endpoints** 메뉴 선택 ([FriendliAI][1])

> 참고: EXAONE 4.0은 FriendliAI의 **Serverless Endpoint**를 통해 API로 제공됩니다. ([FriendliAI][2])

---

### 👤 계정 생성 또는 로그인

2. **Sign up / Log in** 진행

   * 이메일/비밀번호 또는 SSO 로그인 지원
   * 최초 가입 시 무료 체험 크레딧 제공(정책은 변동 가능) ([FriendliAI][1])

---

### 🛡️ API Key(토큰) 발급 메뉴 진입

3. 콘솔 좌측에서 ⚙️**Settings** → 메뉴 **Personal settings** 에서 **API Tokens** 생성 페이지로 이동

   * Friendli Token(예: `flp_xxx…`)은 **Bearer 토큰**으로 사용됩니다. ([FriendliAI][3])

---

### 🔑 API Key 생성

4. **Create / Generate Token** 버튼 클릭하여 토큰 발급

   * 생성된 토큰은 **인증 수단**이므로 안전하게 보관
   * 필요 시 팀 단위로 요청 실행 시 `X-Friendli-Team` 헤더 사용 가능(선택) ([FriendliAI][3])

> 생성 예시:
>
> ```
> flp_2FxxxxxxXsOM2XXXXQDsDYYYYxxxxxxx
> ```

---

### 🧠 모델 선택 및 설정 (옵션)

5. **EXAONE 4.0** 엔드포인트 선택 후 사용할 모델을 지정

   * EXAONE 4.0은 **일반·추론 하이브리드(Agentic 지향)** 구조를 채택합니다. (32B, 1.2B 라인업) ([LG AI Research][4])
   * 모델 선택은 API 호출 시 `"model": "<model-id>"`로 지정
   * 과금/제한은 Friendli **Pricing** 문서 참고(토큰 기반/시간 기반 혼용) ([FriendliAI][5])

---

## ⚠️ 주의사항 및 권장 사항

* 발급된 **Friendli Token**은 외부에 노출되지 않도록 주의
* 코드에 직접 하드코딩하지 말고, `.env` 또는 **환경 변수** 사용 권장
* 공개 저장소(GitHub 등)에 업로드 금지
* 스트리밍 사용 시 `text/event-stream` 응답이며, 일반 응답은 `application/json` 입니다. ([FriendliAI][3])

---

## 📌 활용 팁

* API 호출 시 HTTP Authorization 헤더에 다음과 같이 포함

  ```
  Authorization: Bearer flp_xxxxxxxxxxxxxxxx
  ```

* FriendliAI는 **OpenAI 호환** 방식으로 호출 가능하며, `base_url`만 Friendli로 지정하면 됩니다:

  **Python (OpenAI SDK 예시)**

  ```python
  import os
  from openai import OpenAI
  client = OpenAI(
      api_key=os.getenv("FRIENDLI_TOKEN"),
      base_url="https://api.friendli.ai/serverless/v1",
  )

  chat = client.chat.completions.create(
      model="exaone-4.0-32b-instruct",  # 예시: 실제 모델 코드는 콘솔/문서 확인
      messages=[{"role":"user","content":"안녕하세요, EXAONE 연동 테스트입니다."}]
  )
  print(chat.choices[0].message.content)
  ```

  ([FriendliAI][1])

* **cURL** 예시

  ```bash
  export FRIENDLI_TOKEN="flp_xxx"
  export FRIENDLI_TEAM_ID="xxx" 
  curl -sS https://api.friendli.ai/serverless/v1/chat/completions \
   -H "Authorization: Bearer $FRIENDLI_TOKEN" \
   -H "X-Friendli-Team: $FRIENDLI_TEAM_ID" \
   -H "Content-Type: application/json" \
   -d '{
     "model": "LGAI-EXAONE/EXAONE-4.0.1-32B",
     "messages": [{"role":"user","content":"엑사원으로 인사해 줘"}]
    }'
  ```

  ([FriendliAI][3])

* 문서 바로가기: **QuickStart**, **Chat Completions API**, **OpenAI 호환 가이드**
  – QuickStart: 계정/엔드포인트/모델 선택/호출 흐름 정리 ([FriendliAI][1])
  – Chat Completions API: 엔드포인트·헤더·파라미터·스트리밍 규격 ([FriendliAI][3])
  – OpenAI Compatibility: SDK/호환 호출 방법 안내 ([FriendliAI][6])

---

> 참고 자료
> • EXAONE 4.0 공개 및 Friendli 서버리스 제공 소식(파트너 발표) ([FriendliAI][2])
> • EXAONE 4.0 기술 리포트(하이브리드 구조/에이전틱 툴유즈) ([LG AI Research][4])
> • EXAONE 4.0/3.5/Deep 오픈 리포지터리/허깅페이스(자체 배포 참고) ([GitHub][7])
> • Friendli Pricing(서버리스 토큰·시간 과금) ([FriendliAI][5])

---

[1]: https://friendli.ai/docs/guides/serverless_endpoints/quickstart "QuickStart: Friendli Serverless Endpoints - Friendli Docs"
[2]: https://friendli.ai/blog/lg-ai-research-partnership-exaone-4.0?utm_source=chatgpt.com "LG AI Research Partners with FriendliAI to Launch ..."
[3]: https://friendli.ai/docs/openapi/serverless/chat-completions "Serverless chat completions - Friendli Docs"
[4]: https://www.lgresearch.ai/data/cdn/upload/EXAONE_4_0.pdf?utm_source=chatgpt.com "EXAONE 4.0: Unified Large Language Models Integrating ..."
[5]: https://friendli.ai/pricing/serverless-endpoints?utm_source=chatgpt.com "Friendli Serverless Endpoints Pricing"
[6]: https://friendli.ai/docs/guides/openai-compatibility "OpenAI Compatibility - Friendli Docs"
[7]: https://github.com/LG-AI-EXAONE/EXAONE-4.0?utm_source=chatgpt.com "Official repository for EXAONE 4.0 built by LG AI Research"
