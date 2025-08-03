아래는 **VirusTotal API Key 발급 방법**을 순서대로 자세히 정리한 내용입니다.

---

## ✅ VirusTotal API Key 발급 방법 (2025년 기준)

### 🔗 사이트 접속

1. 웹 브라우저에서 [https://www.virustotal.com/](https://www.virustotal.com/) 접속

---

### 👤 계정 생성 또는 로그인

2. 오른쪽 상단의 **\[Sign in]** 클릭

   * 구글, Microsoft, GitHub 계정으로도 로그인 가능
   * 계정이 없다면 \[Sign up]으로 가입 진행 (무료)

---

### 🛡️ API Key 확인 위치

3. 로그인 후, 우측 상단의 프로필 아이콘 클릭 → **"My API key"** 메뉴 선택
   또는 직접 접속:
   [https://www.virustotal.com/gui/user/<username>/apikey](https://www.virustotal.com/gui/user/your-username/apikey)
   (*URL 중 `<username>` 부분은 본인 계정명으로 자동 설정됩니다.*)

---

### 📄 API Key 종류

| 유형                  | 설명                                                           |
| ------------------- | ------------------------------------------------------------ |
| **Public API Key**  | 가입 시 자동 발급. 무료이지만 **1분당 4회 요청 제한**                           |
| **Premium API Key** | 유료 가입 필요. **속도/쿼터 상한 해제 및 고급 기능** 제공 (예: 리얼타임 스트리밍, 바이너리 분석) |

→ 대부분의 일반적인 **IP, Hash 조회는 Public API Key**로 충분합니다.

---

### ✅ 확인 예시

발급된 키는 다음과 같이 보입니다:

```
API Key:
3b132xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

> **주의:** 이 키는 인증 수단이며 **절대로 외부에 노출되어선 안 됩니다**.
> 스크립트에 사용할 땐 환경 변수로 저장하거나 `.env` 파일 사용을 권장합니다.

---

## 📌 활용 팁

* 사용량 초과 시 `"Quota Exceeded"` 오류 반환
* Python/Bash 등 다양한 언어에서 `x-apikey` 헤더로 사용
* 하루 수천 건 이상 쿼리가 필요한 경우 **Premium 신청 필요**

---
