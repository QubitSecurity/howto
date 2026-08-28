아래는 **HyperCLOVA X (네이버 클라우드 AI — CLOVA Studio)** 서비스의 API Key (CLOVA Studio API Key) 발급 및 사용 안내입니다.

---

## ✅ HyperCLOVA X API Key 발급 및 사용 방법 (최신 기준)

### 🔗 콘솔 접속 및 로그인

1. 웹 브라우저에서 **네이버 클라우드 플랫폼 콘솔**([https://clovastudio.ncloud.com/](https://clovastudio.ncloud.com/))에 접속하신 후 로그인합니다.
2. CLOVA Studio 사용을 위한 약관 동의 및 신청이 필요한 경우 절차를 진행합니다.

---

### 🏗️ Test App 또는 Service App 생성

3. CLOVA Studio 대시보드에서 "API키" > **Test App** 또는 **Service App**을 생성합니다
   * Test App은 개발 및 평가용이며, 이후 Service App으로 전환 가능합니다.
   * App 생성 시 모델(HyperCLOVA X), 옵션, 사용 목적 등을 선택하고 설정합니다.

---

### 🔑 API Key 발급

4. App 생성 완료 후, **“Issue API Key”** 버튼을 통해 API Key를 발급받습니다.
   * 발급된 키는 `CLOVASTUDIO_API_KEY` 환경 변수로 설정 권장 (`nv-*`로 시작 가능).
   * `langchain-naver` 등의 라이브러리에서 자동 로드할 수 있도록 설정합니다.
   * **[참고] REST API 직접 호출 시**: `X-NCP-CLOVASTUDIO-API-KEY` 뿐만 아니라 API Gateway 환경에 따라 `X-NCP-APIGW-API-KEY` 발급이 추가로 필요할 수 있습니다. (LangChain 등 추상화 라이브러리를 사용하면 환경 변수 설정으로 단순화됩니다.)

---

### 📡 API Key 활용 방식

5. 아래와 같이 환경 변수 설정:

   ```bash
   export CLOVASTUDIO_API_KEY="your-api-key-here"
   ```

6. Python 코드 예 (`langchain-naver` 통합 사용 예시):

   ```python
   from langchain_naver import ChatClovaX

   # 주의: "HCX-005" 등 모델명은 최신 업데이트에 따라 변경될 수 있습니다. 공식 문서를 확인해 주기적으로 업데이트하세요.
   chat = ChatClovaX(model="HCX-005", temperature=0.5)
   response = chat.generate("안녕하세요, HyperCLOVA X!")
   print(response)
   ```

---

## ⚠️ 주의사항 및 권장 설정

* API Key는 **절대로 외부 공유 금지**
  * `.gitignore` 또는 환경 변수 설정을 적극 활용할 것
* 과도한 요청 시 요금 과금 가능하므로 호출량 모니터링 필요
* Private Key 유효기간 또는 제한 설정 가능 시 없어도 사용 가능

---

## 📌 활용 팁 & 참고 사항

* CLOVA Studio에서는 채팅 모델 외에도 튜닝, RAG, embedding API 등 다양한 기능 제공
* Chat 모델과 Embedding 모델은 `langchain-naver` 패키지에서 지원되므로 통합 사용 시 유용
* HyperCLOVA X 기반의 새로운 모델 라인업이 지속 추가되므로 정기적인 모델명 확인 권장.

---

## 🧾 요약 테이블

| 항목 | 설명 |
| --- | --- |
| 인증 방식 | CLOVA Studio에서 Test/App 생성 후 발급된 API Key (`CLOVASTUDIO_API_KEY`) |
| 직접 호출 시 | `X-NCP-CLOVASTUDIO-API-KEY`, `X-NCP-APIGW-API-KEY` (API Gateway 필요 시) 함께 사용 |
| 라이브러리 호출 | 환경 변수 설정 후 `langchain-naver` 등 이용하여 ChatClovaX 클래스 사용 |
| 키 관리 방법 | 환경 변수 또는 `.env` 파일로 관리, 외부 노출 금지 |
| 추가 모델 활용 | embedding, 챗봇, 튜닝, RAG 등 CLOVA Studio 기능 활용 가능 |
| 요금 및 제한 | 토큰 기반 과금, 호출량은 콘솔에서 사용량 확인 가능 |
