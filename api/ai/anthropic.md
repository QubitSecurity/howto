다음은 **Claude (by Anthropic) 모델**을 API로 사용하기 위한 API Key 발급 및 설정 방법에 대한 자세한 가이드입니다.

---

## ✅ Claude (Anthropic) API Key 발급 및 사용 방법 (2025년 기준)

### 🔗 사이트 접속 및 로그인

1. 웹 브라우저에서 [https://console.anthropic.com](https://console.anthropic.com) 접속
2. **Sign up** 또는 **Sign in**을 통해 계정 생성 또는 로그인

   * Google, GitHub 계정 연동 가능
   * 전화번호 인증은 현재 요구되지 않음

---

### 🔑 API Key 발급 절차

3. 로그인 후 우측 상단 프로필 클릭 → **“API Keys”** 메뉴 선택
   또는 바로가기: [https://console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys)
4. **\[Create Key]** 버튼 클릭

   * 키 이름 입력 (예: `my-clause-dev-key`)
   * 생성된 키는 한 번만 전체 표시되므로 **반드시 복사해 보관**

> 생성 예시:
>
> ```
> sk-ant-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
> ```

---

### 📡 API Key 사용 예시

#### 🔸 기본 HTTP 요청

```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: sk-ant-xxxxxxxxxxxxxxxxx" \
  -H "anthropic-version: 2023-06-01" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "claude-3-opus-20240229",
    "max_tokens": 1024,
    "messages": [
      {"role": "user", "content": "한국 사이버보안 트렌드를 요약해줘"}
    ]
  }'
```

#### 🔸 Python (공식 SDK)

```bash
pip install anthropic

from anthropic import Anthropic

client = Anthropic(api_key="sk-ant-xxxxxxxxxxxxxxxxx")

message = client.messages.create(
    model="claude-3-sonnet-20240229",
    max_tokens=1024,
    messages=[{"role": "user", "content": "보안 정책 요약해줘"}]
)

print(message.content[0].text)
```

---

## 🤖 Claude 모델 종류 (2025년 8월 기준)

| 모델명               | 특성            | 용도 예시                     |
| ----------------- | ------------- | ------------------------- |
| `claude-3-opus`   | 최고 성능, GPT-4급 | 고정확 요약, 코딩, 법률문서, 분석 등    |
| `claude-3-sonnet` | 성능-속도 균형      | 실시간 응답, 대화형 시스템           |
| `claude-3-haiku`  | 초고속 응답, 소형 경량 | 모바일 앱, 간단 요약, 실시간 인터페이스 등 |

> 📌 Claude-3 시리즈는 모두 **20만 토큰 context** 지원
>
> * GPT-4의 128k 대비 더 넓은 입력 가능
> * 문서형 데이터 분석, 장문 RAG에 유리

---

## ⚠️ 주의 사항

* **API Key는 비공개로 안전하게 보관**해야 하며, 코드 내 하드코딩 금지

  * 환경 변수 또는 `.env` 파일 사용 권장
* 사용량 과금은 [https://console.anthropic.com/billing](https://console.anthropic.com/billing)에서 확인 가능
* 무료 크레딧은 제공되지 않으며, **신용카드 등록 후 유료 사용 시작**

---

## 📌 활용 팁

* LangChain, LlamaIndex 등 오픈소스 프레임워크에서도 Claude API 연동 지원
* 한국어 대응 우수 (GPT-4급 수준), 다만 구어체 생성 시 약간의 어색함 존재
* Claude는 입력 프롬프트에 대해 매우 \*\*"협조적이고 신중한 스타일"\*\*을 유지

---

## ✍️ 정리

| 항목         | 내용                                                             |
| ---------- | -------------------------------------------------------------- |
| 콘솔 주소      | [https://console.anthropic.com](https://console.anthropic.com) |
| API Key 위치 | Settings → API Keys 메뉴                                         |
| 대표 모델      | `claude-3-opus`, `sonnet`, `haiku`                             |
| 인증 헤더      | `x-api-key`, `anthropic-version`                               |
| 문서 링크      | [Anthropic API Docs](https://docs.anthropic.com/)              |

---
