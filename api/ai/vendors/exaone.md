## ✅ EXAONE API Key 발급 및 연동 가이드 (2026년 3월)

### 🔗 1. 사이트 접속 및 준비
1. 웹 브라우저에서 **FriendliAI 콘솔** 접속: [https://friendli.ai](https://friendli.ai)
2. 로그인 후 좌측 메뉴에서 **Serverless Endpoints** 또는 **Dedicated Endpoints** 메뉴를 선택합니다. 
> 🚨 **중요 안내:** 최근 정책 변경으로 인해 EXAONE 4.0 모델은 공용 서버리스(Serverless) 기본 목록에서 제외되었을 수 있습니다. 엑사원 모델을 반드시 사용해야 하는 경우, 대시보드의 **Dedicated Endpoints** 메뉴에서 엑사원 모델을 직접 배포(Deploy)하여 전용 엔드포인트를 생성해야 합니다.

---

### 👤 2. 계정 생성 또는 로그인
* 이메일/비밀번호 또는 SSO 로그인을 지원합니다.
* 최초 가입 시 무료 체험 크레딧이 제공됩니다(정책은 변동 가능).

---

### 🛡️ 3. API Key(토큰) 발급
1. 콘솔 좌측 하단의 ⚙️**Settings** $\rightarrow$ **Personal settings** 내 **API Tokens** 페이지로 이동합니다.
2. **Create / Generate Token** 버튼을 클릭하여 토큰을 발급합니다.
   * Friendli Token(예: `flp_xxx…`)은 API 호출 시 **Bearer 토큰**으로 사용되는 핵심 인증 수단이므로 안전하게 보관하세요.
   * 팀 단위로 API를 관리한다면 `X-Friendli-Team` 헤더에 팀 ID를 추가로 사용할 수 있습니다.

---

### 🧠 4. 모델 선택 및 과금 안내
* **EXAONE 4.0**은 일반·추론 하이브리드(Agentic 지향) 구조를 채택한 고성능 모델입니다(32B, 1.2B 라인업 등).
* API 호출 시 `"model"` 파라미터에 사용할 모델 ID(또는 배포한 Dedicated Endpoint ID)를 정확히 지정해야 합니다.
* 과금 및 제한 사항은 Friendli Pricing 문서(토큰 기반/시간 기반 혼용)를 참고하세요.

---

## ⚠️ 주의사항 및 보안 권장 사항
* 발급된 **Friendli Token**은 외부에 노출되지 않도록 각별히 주의하세요.
* 코드에 직접 하드코딩하지 말고, `.env` 파일이나 **OS 환경 변수**를 사용하는 것을 강력히 권장합니다.
* 공개 저장소(GitHub 등)에 코드를 업로드할 때 키가 포함되지 않도록 주의하세요.
* 스트리밍(Streaming) 호출 시 `text/event-stream` 형식으로 응답하며, 일반 호출 시 `application/json` 형식으로 응답합니다.

---

## 📌 언어별 API 호출 예제 (활용 팁)

API 호출 시 HTTP `Authorization` 헤더에 발급받은 토큰을 다음과 같이 포함해야 합니다.
`Authorization: Bearer flp_xxxxxxxxxxxxxxxx`

> **※ 주의:** 아래 예제의 URL(`.../serverless/...`) 및 모델명은 서버리스 테스트용 기준입니다. Dedicated Endpoint로 엑사원을 구축하셨다면 주소를 `https://api.friendli.ai/dedicated/v1/...`로 변경하고, 모델명에 발급받은 Endpoint ID를 넣으세요.

### 🐍 Python (OpenAI SDK 호환)
FriendliAI는 OpenAI 호환 방식을 지원하므로 `base_url`만 변경하여 기존 코드를 쉽게 재사용할 수 있습니다.
```python
import os
from openai import OpenAI

client = OpenAI(
    api_key=os.getenv("FRIENDLI_TOKEN"),
    base_url="https://api.friendli.ai/serverless/v1", # Dedicated 사용 시 URL 변경 필요
)

chat = client.chat.completions.create(
    model="LGAI-EXAONE/EXAONE-4.0.1-32B",  # 실제 사용 가능한 모델 ID 또는 전용 Endpoint ID 입력
    messages=[{"role":"user","content":"안녕하세요, EXAONE 연동 테스트입니다."}]
)
print(chat.choices[0].message.content)
```

### 💻 cURL
```bash
export FRIENDLI_TOKEN="flp_xxxxxxxxxxxxxxxx"
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

### 🪟 PowerShell (Windows)
> **🚨 매우 중요 (Windows PowerShell 5.1 기준)**
> 스크립트(`.ps1`) 내에 한글 프롬프트를 작성할 경우, 파일을 저장할 때 인코딩을 반드시 `UTF-8 (BOM 포함)`으로 설정해야 파싱 에러(문법 오류)가 발생하지 않습니다. 또한, 서버의 JSON 역직렬화 에러(400 Bad Request)를 막기 위해 아래와 같이 `-Compress` 옵션과 바이트 강제 변환 방식을 사용해야 합니다.

#### 옵션 1: 단순화된 버전 (팀 ID 제거 - 개인 사용 권장)
```powershell
# 1. 팀 ID 없이 토큰만 설정
$FRIENDLI_TOKEN = "flp_xxxxxxxxxxxxxxxx"

# 2. 헤더에도 팀 ID 제거 완료
$headers = @{
    "Authorization" = "Bearer $FRIENDLI_TOKEN"
    "Content-Type"  = "application/json"
}

# 3. 에러 방지를 위해 영문 메시지 + 동작하는 Llama 모델 사용
$body = @{
    model = "meta-llama-3.1-8b-instruct"
    messages = @(
        @{role="user"; content="Hello! Are you working without the team ID?"}
    )
}

# 4. JSON 변환 및 호출
$json = $body | ConvertTo-Json -Depth 5 -Compress
$bytes = [System.Text.Encoding]::UTF8.GetBytes($json)

$response = Invoke-RestMethod -Uri "https://api.friendli.ai/serverless/v1/chat/completions" -Method Post -Headers $headers -Body $bytes

Write-Host "========================================"
Write-Host $response.choices[0].message.content
Write-Host "========================================"
```

#### 옵션 2: 팀 워크스페이스용 버전 (팀 ID 포함)
```powershell
# 1. 환경 변수 설정 (본인의 키값으로 변경)
$FRIENDLI_TOKEN = "flp_xxxxxxxxxxxxxxxx"
$FRIENDLI_TEAM_ID = "xxx"

# 2. 헤더 설정 (팀 ID 포함)
$headers = @{
    "Authorization"   = "Bearer $FRIENDLI_TOKEN"
    "X-Friendli-Team" = $FRIENDLI_TEAM_ID
    "Content-Type"    = "application/json"
}

# 3. 요청 본문 (파싱 에러 방지를 위해 영문 프롬프트 사용)
$body = @{
    model = "LGAI-EXAONE/EXAONE-4.0.1-32B"
    messages = @(
        @{role="user"; content="Hello EXAONE!"}
    )
}

# 4. JSON 변환 및 UTF-8 강제 인코딩 (400 에러 완벽 방지)
$json = $body | ConvertTo-Json -Depth 5 -Compress
$bytes = [System.Text.Encoding]::UTF8.GetBytes($json)

# 5. 콘솔 출력 인코딩 설정 및 API 호출
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$response = Invoke-RestMethod -Uri "https://api.friendli.ai/serverless/v1/chat/completions" -Method Post -Headers $headers -Body $bytes

# 6. 결과 출력
Write-Host "========================================"
Write-Host $response.choices[0].message.content
Write-Host "========================================"
```

---

## 📚 참고 문서 바로가기
* **QuickStart:** 계정/엔드포인트/모델 선택/호출 흐름 가이드
* **Chat Completions API:** 엔드포인트·헤더·파라미터·스트리밍 규격
* **OpenAI Compatibility:** SDK/호환 호출 방법 안내
* EXAONE 4.0 공개 및 Friendli 서버리스 제공 소식
* EXAONE 4.0 기술 리포트 (하이브리드 구조/에이전틱 툴유즈)
* EXAONE 4.0/3.5/Deep 공식 오픈 리포지터리/허깅페이스
* Friendli Pricing (서버리스 토큰·시간 과금 정책)

---
