# 🤖 PLURA-AI 연동을 위한 각 서비스별 API 생성 가이드

본 디렉터리는 주요 생성형 AI 서비스(ChatGPT, Gemini, Claude, HyperCLOVA X **및 EXAONE**)의 API Key 발급 및 사용 방법을 정리한 문서입니다.
서비스별 인증 절차와 호출 구조를 확인하고, 각 환경에 맞는 연동을 빠르게 구성해 보세요.

---

## ✅ 주요 AI 서비스 연동 비교

| 서비스                | 인증 방식                | API 문서 링크                                                 | 비고                                |
| ------------------ | -------------------- | --------------------------------------------------------- | --------------------------------- |
| ChatGPT (OpenAI)   | API Key              | [OpenAI Docs](https://platform.openai.com/docs)           | GPT-4o 사용 가능                      |
| Google Gemini      | OAuth 2.0 + API Key  | [Gemini API](https://ai.google.dev/)                      | PaLM → Gemini로 통합                 |
| Claude (Anthropic) | API Key              | [Anthropic API Docs](https://docs.anthropic.com/)         | Claude 3 Opus / Sonnet / Haiku 지원 |
| HyperCLOVA X       | OAuth / API Key      | [NAVER Cloud AI](https://guide.ncloud-docs.com/)          | NCP Console에서 사전 설정 필요            |
| **EXAONE (LG)**    | **API Key (파트너 경로)** | (파트너 콘솔/FriendliAI 또는 LG AI Research 안내 문서 경로 · 내부 문서 참조) | 국내 도입 친화, 한국어 강점, 멀티모달/추론 라인업     |

> ❌ **뤼튼 테크놀로지**(Wrtn Technologies)는 자체 LLM을 보유하고 있지 않으며,
> 내부적으로 **GPT API를 프록시**하는 구조이므로 본 AI 연동 대상에서 제외합니다.

---

## 📁 문서 목록

| 파일명                                        | 설명                                               |
| ------------------------------------------ | ------------------------------------------------ |
| [`chatgpt.md`](./vendors/chatgpt.md)       | ChatGPT (OpenAI) API Key 발급 및 사용 방법              |
| [`gemini.md`](./vendors/gemini.md)         | Google Gemini API 설정, 키 발급, 호출 예시 포함             |
| [`chatclovax.md`](./vendors/chatclovax.md) | HyperCLOVA X (네이버 클라우드) 연동 설정 및 호출 가이드           |
| [`anthropic.md`](./vendors/anthropic.md)   | Claude (Anthropic) API Key 발급 및 모델 사용 안내         |
| **[`exaone.md`](./vendors/exaone.md)**     | **LG EXAONE 연동 가이드 (파트너 경로/API Key 발급 & 호출 예시)** |

> `exaone.md`에는 다음을 포함합니다:
> ① 파트너 경로(API Key 발급 흐름) ② 기본 Chat/Completions 호출 예시(REST & Python/JS)
> ③ 멀티모달 입력(텍스트+이미지) 샘플 ④ 토큰/요금·모델 선택 팁 ⑤ 에러/리트라이 가이드

---

## 💡 API 발급 필요 여부

| 서비스          | UI 표시                | 설명                                      |
| ------------ | -------------------- | --------------------------------------- |
| ChatGPT      | 🔲 API 키 발급 필요함      | 사용자 콘솔에서 직접 발급 필요                       |
| Gemini       | 🔲 API 키 발급 필요함      | Google Cloud Console 필요                 |
| Claude       | 🔲 API 키 발급 필요함      | Anthropic Console > API Key 메뉴에서 발급     |
| HyperCLOVA X | 🔲 API 키 발급 필요함      | NCP Console > CLOVA Studio 필요           |
| **EXAONE**   | **🔲 API 키(파트너) 필요** | **파트너 콘솔(예: FriendliAI) 또는 지정 경로에서 발급** |

---

### 추가 메모 (EXAONE)

* **권장 연동 흐름**: 파트너 콘솔에서 프로젝트 생성 → API Key 발급 → 환경변수 등록 → 기본 Chat/Completions 엔드포인트 호출 → 응답 형식/스트리밍 옵션 검증 → 멀티모달/함수호출(툴유즈) 확장.
* **배포 옵션**: 클라우드 파트너 엔드포인트(권장) 또는 오픈 가중치 기반의 사내 배포(보안/망분리 환경) 중 선택.
* **보안/컴플라이언스**: 국내 데이터 거버넌스 요건(개인정보/산업기밀) 적용 시, 사내 게이트웨이/프록시 레이어와 로깅/레이트리밋 정책을 `PLURA-AI` 표준으로 통합 권장.
