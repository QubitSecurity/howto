아래는 **HyperCLOVA X (네이버 클라우드 AI — CLOVA Studio)** 서비스의 API Key (CLOVA Studio API Key) 발급 및 사용 안내입니다.

---

## ✅ HyperCLOVA X API Key 발급 및 사용 방법 (2025년 기준)

### 🔗 콘솔 접속 및 로그인

1. 웹 브라우저에서 **네이버 클라우드 플랫폼 콘솔**([https://clovastudio.ncloud.com/](https://clovastudio.ncloud.com/))에 접속하신 후 로그인합니다.
2. CLOVA Studio 사용을 위한 약관 동의 및 신청이 필요한 경우 절차를 진행합니다 ([python.langchain.com][1], [api.ncloud-docs.com][2]).

---

### 🏗️ Test App 또는 Service App 생성

3. CLOVA Studio 대시보드에서 **Test App** 또는 **Service App**을 생성합니다

   * Test App은 개발 및 평가용이며, 이후 Service App으로 전환 가능 ([python.langchain.com][1]).
   * App 생성 시 모델(HyperCLOVA X), 옵션, 사용 목적 등을 선택하고 설정합니다.

---

### 🔑 API Key 발급

4. App 생성 완료 후, **“Issue API Key”** 버튼을 통해 API Key를 발급받습니다.

   * 발급된 키는 `CLOVASTUDIO_API_KEY` 환경 변수로 설정 권장 (`nv‑*`로 시작 가능) ([python.langchain.com][3], [guide.ncloud-docs.com][4]).
   * `langchain-naver` 등의 라이브러리에서 자동 로드할 수 있도록 설정합니다.

---

### 📡 API Key 활용 방식

5. 아래와 같이 환경 변수 설정:

   ```bash
   export CLOVASTUDIO_API_KEY="your-api-key-here"
   ```
6. Python 코드 예:

   ```python
   from langchain_naver import ChatClovaX

   chat = ChatClovaX(model="HCX-005", temperature=0.5)
   response = chat.generate("안녕하세요, HyperCLOVA X!")
   print(response)
   ```

   (LangChain Naver integration 사용 예) ([python.langchain.com][1], [GitHub][5])

---

## ⚠️ 주의사항 및 권장 설정

* API Key는 **절대로 외부 공유 금지**

  * `.gitignore` 또는 환경 변수 설정을 적극 활용할 것 ([guide.ncloud-docs.com][6], [python.langchain.com][3])
* 과도한 요청 시 요금 과금 가능하므로 호출량 모니터링 필요
* Private Key 유효기간 또는 제한 설정 가능 시 없어도 사용 가능

---

## 📌 활용 팁 & 참고 사항

* CLOVA Studio에서는 채팅 모델 외에도 튜닝, RAG, embedding API 등 다양한 기능 제공 ([ncloud-forums.com][7])
* Chat 모델과 Embedding 모델은 `langchain-naver` 패키지에서 지원되므로 통합 사용 시 유용 ([python.langchain.com][3])
* HyperCLOVA X 기반의 **Inference AI** 모델은 2025년 상반기 중 출시 예정이며, 이후 다양한 자동화/도구 연동 기능 지원 예정 ([fntimes.com][8])

---

## 🧾 요약 테이블

| 항목        | 설명                                                               |
| --------- | ---------------------------------------------------------------- |
| 인증 방식     | CLOVA Studio에서 Test/App 생성 후 발급된 API Key (`CLOVASTUDIO_API_KEY`) |
| API 호출 방식 | 환경 변수 설정 후 `langchain-naver` 등 이용하여 ChatClovaX 클래스 사용            |
| 키 관리 방법   | 환경 변수 또는 `.env` 파일로 관리, 외부 노출 금지                                 |
| 추가 모델 활용  | embedding, 챗봇, 튜닝, RAG 등 CLOVA Studio 기능 활용 가능                   |
| 요금 및 제한   | 토큰 기반 과금, 호출량은 콘솔에서 사용량 확인 가능                                    |

---

주석

[1]: https://python.langchain.com/docs/integrations/chat/naver/?utm_source=chatgpt.com "ChatClovaX - ️ LangChain"
[2]: https://api.ncloud-docs.com/docs/ai-naver-clovastudio-summary?utm_source=chatgpt.com "CLOVA Studio 개요 - API 가이드"
[3]: https://python.langchain.com/docs/integrations/providers/naver/?utm_source=chatgpt.com "NAVER - ️ LangChain"
[4]: https://guide.ncloud-docs.com/docs/en/apigw-apigw-2-5?utm_source=chatgpt.com "API Keys"
[5]: https://github.com/langchain-ai/langchain/blob/master/docs/docs/integrations/chat/naver.ipynb?utm_source=chatgpt.com "langchain/docs/docs/integrations/chat/naver.ipynb at master - GitHub"
[6]: https://guide.ncloud-docs.com/docs/apigw-apigw-2-5?utm_source=chatgpt.com "API Keys 화면 및 목록"
[7]: https://www.ncloud-forums.com/topic/307/?utm_source=chatgpt.com "(3부) CLOVA Studio를 이용해 RAG 구현하기 - 활용법 & Cookbook"
[8]: https://www.fntimes.com/html/view.php?ud=202504240926366165141825007d_18&utm_source=chatgpt.com "Naver Cloud, “Inference AI is Essential to Sovereign Strategy ..."
