# 🤖 AI 서비스 연동 API 가이드

본 디렉터리는 주요 생성형 AI 서비스(ChatGPT, Gemini, Wrtn Tech, HyperCLOVA X)의 API Key 발급 및 사용 방법을 정리한 문서입니다.  
서비스별 인증 절차와 호출 구조를 확인하고, 각 환경에 맞는 연동을 빠르게 구성해 보세요.

---

## ✅ 주요 AI 서비스 연동 비교

| 서비스              | 인증 방식                       | API 문서 링크                                                           | 비고                              |
| ------------------ | --------------------------- | --------------------------------------------------------------------- | --------------------------------- |
| ChatGPT (OpenAI)   | API Key                     | [OpenAI Docs](https://platform.openai.com/docs)                       | GPT-4o 사용 가능                  |
| Google Gemini      | OAuth 2.0 + API Key         | [Gemini API](https://ai.google.dev/)                                  | PaLM → Gemini로 통합              |
| Wrtn Tech (뤼튼)    | API Key or Prompt API       | [Wrtn Docs](https://wrtn.io)                                          | 비공식 API 또는 프롬프트 송수신   |
| HyperCLOVA X       | OAuth / API Key             | [NAVER Cloud AI](https://guide.ncloud-docs.com/)                      | NCP Console에서 사전 설정 필요    |

---

## 💡 API 발급 필요 여부

| 서비스           | UI 표시               | 설명                             |
|------------------|------------------------|----------------------------------|
| ChatGPT          | 🔲 API 키 발급 필요함     | 사용자 콘솔에서 직접 발급 필요       |
| Gemini           | 🔲 API 키 발급 필요함     | Google Cloud Console 필요        |
| Wrtn Tech        | 🔲 비공식 API 사용 가능    | 계정 인증 기반 API 구성 필요        |
| HyperCLOVA X     | 🔲 API 키 발급 필요함     | NCP Console > CLOVA Studio 필요  |

---

## 📁 문서 목록

| 파일명           | 설명                                                 |
|------------------|------------------------------------------------------|
| `chatgpt.md`     | ChatGPT (OpenAI) API Key 발급 및 사용 방법           |
| `gemini.md`      | Google Gemini API 설정, 키 발급, 호출 예시 포함      |
| `wrtntech.md`    | Wrtn 비공식 API 인증 및 프롬프트 호출 방식 안내       |
| `chatclovax.md`  | HyperCLOVA X (네이버 클라우드) 연동 설정 및 호출 가이드 |

---

## ✍️ 작성자

QubitSecurity, 2025  
문서 개선 제안은 PR 또는 Issue로 자유롭게 남겨주세요.
