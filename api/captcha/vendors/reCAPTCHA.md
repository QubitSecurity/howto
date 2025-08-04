아래는 **Google reCAPTCHA API** 키 생성 사용자 가이드)입니다.

---

## ✅ Google reCAPTCHA API Key 생성 방법 (2025년 기준)

### 🔗 Google Cloud Console 접속

1. 웹 브라우저에서 [https://console.cloud.google.com/](https://console.cloud.google.com/) 접속

---

### 🏢 프로젝트 선택 및 reCAPTCHA 활성화

2. 상단 메뉴에서 **reCAPTCHA Enterprise가 활성화된 프로젝트** 선택
   예: `plura-v5-10-1737158662036`

   > 프로젝트가 없다면 새 프로젝트를 생성한 뒤,
   > `API 및 서비스 > 라이브러리`에서 **reCAPTCHA Enterprise**를 검색해 **활성화**해야 합니다.

---

### 🔐 API 키 관리 페이지 이동

3. 왼쪽 메뉴에서 **\[API 및 서비스] > \[인증 정보(Credentials)]** 클릭
   또는 직접 접속:
   [https://console.cloud.google.com/apis/credentials](https://console.cloud.google.com/apis/credentials)

---

### 🔎 기존 API 키 확인

4. 화면 중앙의 **API 키 목록**에서 사용할 키 확인

   * 이미 발급된 키가 있다면 이름을 통해 구분
   * "제한됨"으로 표시된 경우, **reCAPTCHA Enterprise**가 포함되어 있는지 확인 필요

---

### ⚙️ API 키 제한 설정 확인 (선택 사항)

5. 특정 API만 허용하도록 **제한된 키**인 경우:
   해당 키 클릭 → "API 제한"에서 **reCAPTCHA Enterprise**가 선택되어 있는지 확인

   > 키가 너무 많은 API에 허용되어 있으면 **보안에 취약**할 수 있음

---

### 🆕 새 API 키 생성

6. 새 키가 필요한 경우:

   * 상단의 **\[+ 새 API 키 만들기]** 클릭
   * 생성된 키를 안전한 위치에 보관

---

## ✅ 발급된 API Key 예시

```
API Key:
AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

> **주의:** 이 키는 인증 수단이며 **절대로 외부에 노출되어선 안 됩니다.**
> `.env` 파일 또는 환경 변수로 안전하게 저장하세요.

---

## 📌 활용 팁

* 프론트엔드에서 직접 사용 시, **도메인 제한 설정 필수**
* 백엔드에서는 비공개 환경에서만 사용
* [reCAPTCHA 문서](https://cloud.google.com/recaptcha-enterprise/docs/create-key) 참고

---

## 📂 추가 참고 문서

* [reCAPTCHA Enterprise 공식 가이드](https://cloud.google.com/recaptcha-enterprise/docs/)
* [API Key 관리 모범 사례](https://cloud.google.com/docs/authentication/api-keys)

---

필요하시면 **프론트엔드 연동 예제 (HTML + JS)** 또는 \*\*서버측 검증 예제 (Python / Node.js)\*\*도 함께 제공해 드릴 수 있습니다.
