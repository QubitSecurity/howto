다음은 **Google Gemini (PaLM)** 서비스의 API Key 발급 및 사용을 위한 안내 문서입니다.

---

## ✅ Google Gemini API Key 발급 방법 (2025년 기준)

### 🔗 사이트 접속

1. 웹 브라우저에서 [https://makersuite.google.com/](https://makersuite.google.com/) 접속
   또는 [https://ai.google.dev/](https://ai.google.dev/)에서 전체 문서 확인 가능

---

### 👤 Google 계정으로 로그인

2. 상단의 **\[Sign in]** 버튼 클릭

   * 반드시 **개인 Gmail 계정 또는 Google Workspace 계정** 필요
   * 기업 계정(Google Cloud Organization)의 경우 관리자가 API 사용을 제한할 수 있음

---

### 🧪 MakerSuite 프로젝트 생성

3. 로그인 후, [Google Cloud Console](https://console.cloud.google.com/)에 접속

   * 새 프로젝트 생성 또는 기존 프로젝트 선택
   * 상단 탐색 바에서 프로젝트 이름을 확인

---

### 🛠️ Gemini API 사용 설정

4. 좌측 메뉴 > **"API 및 서비스" → "라이브러리"** 이동

   * 검색창에 `Gemini` 또는 `Generative Language API` 입력
   * **"Gemini API"** 선택 후 **\[사용]** 버튼 클릭

---

### 🔑 API Key 생성

5. **"사용자 인증 정보" → \[사용자 인증 정보 만들기] → "API 키"** 선택

   * 생성된 API 키는 복사하여 안전하게 보관
   * 필요 시, API 키 이름 변경 또는 제한 설정 가능 (IP 제한 등)

> 생성 예시:
>
> ```
> AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxx
> ```

---

### 📄 모델 사용 및 문서 참고

* Gemini Pro, Gemini Flash 등 다양한 모델 사용 가능
* 사용 시 `model` 파라미터에 `"gemini-pro"` 또는 `"gemini-pro-vision"` 지정
* Python 사용 예시는 [https://ai.google.dev/tutorials/python\_quickstart](https://ai.google.dev/tutorials/python_quickstart) 참고

---

## ⚠️ 주의사항 및 권장 설정

* 생성된 API 키는 **유료 프로젝트와 연결 시 요금이 발생할 수 있음**
* API 호출량은 \[Cloud Console > 사용량] 메뉴에서 확인 가능
* 키 유출 시 오용 방지를 위해 **"API Key 제한" 설정**을 적극 권장

---

## 📌 활용 팁

* Python에서는 `google.generativeai` 패키지를 통해 사용

  ```bash
  pip install google-generativeai
  ```

  ```python
  import google.generativeai as genai

  genai.configure(api_key="YOUR_API_KEY")

  model = genai.GenerativeModel("gemini-pro")
  response = model.generate_content("Hello, Gemini!")
  print(response.text)
  ```

* 텍스트뿐만 아니라 이미지 입력도 가능 (`gemini-pro-vision` 사용 시)

---
