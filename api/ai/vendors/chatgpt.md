다음은 **ChatGPT (OpenAI)** 서비스의 API Key 발급 방법을 사용자에게 안내하기 위한 문서입니다. 

---

## ✅ ChatGPT (OpenAI) API Key 발급 방법 (2025년 기준)

### 🔗 사이트 접속

1. 웹 브라우저에서 [https://platform.openai.com/](https://platform.openai.com/) 접속

---

### 👤 계정 생성 또는 로그인

2. 오른쪽 상단의 **\[Sign up]** 또는 **\[Log in]** 클릭

   * 이메일 기반 회원 가입 또는 Google/Microsoft 계정으로 로그인 가능
   * 가입 시 전화번호 인증 필수

---

### 🛡️ API Key 발급 메뉴 진입

3. 로그인 후, 우측 상단 사용자 이름 클릭 → **"API keys"** 메뉴 선택
   또는 직접 접속:
   [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys)

---

### 🔑 API Key 생성

4. **\[Create new secret key]** 버튼 클릭

   * 이름을 지정하거나 기본 이름 그대로 사용
   * 생성된 키는 **한 번만 전체 표시되므로 반드시 복사 후 보관**

> 생성 예시:
>
> ```
> sk-2FxxxxxxXsOM2XXXXQDsDYYYYxxxxxxx
> ```

---

### 🧠 모델 선택 및 설정 (옵션)

5. 기본적으로 GPT-3.5가 사용되며, 유료 계정은 GPT-4 및 **GPT-4o** 모델 호출 가능

   * 모델 선택은 API 호출 시 `"model": "gpt-4o"` 등으로 지정
   * 요금제별 제한은 [가격 안내 페이지](https://openai.com/pricing) 참고

---

## ⚠️ 주의사항 및 권장 사항

* 발급된 API Key는 **인증 수단**이며, 외부에 노출되지 않도록 주의
* 코드에 직접 입력하지 말고, `.env` 또는 환경 변수 사용 권장
* 공개 저장소(GitHub 등)에 업로드 금지

---

## 📌 활용 팁

* API 호출 시 HTTP Authorization 헤더에 다음과 같이 포함

  ```
  Authorization: Bearer sk-xxxxxxxxxxxxxxxx
  ```
* OpenAI 공식 라이브러리 (Python, Node.js 등) 제공
* 사용량은 대시보드에서 확인 가능:
  [https://platform.openai.com/account/usage](https://platform.openai.com/account/usage)

---
