## ✅ `recovering-restart.sh` (최종 완성본)

### 📌 요약: 이 스크립트는 다음을 수행합니다

| 단계  | 설명                                      |
| --- | --------------------------------------- |
| 1️⃣ | Solr 실행 여부 확인 및 `stop` 시도               |
| 2️⃣ | 실패 시 `kill -9`로 강제 종료                   |
| 3️⃣ | `recovery`, `tlog` 디렉토리 내부 정리           |
| 4️⃣ | `write.lock` 파일 조건부 삭제 (Solr가 꺼진 상태에서만) |
| 5️⃣ | `start -cloud`로 재기동                     |
| 6️⃣ | `solr status` 명령으로 확인 후 로그 기록           |

---

### 🛠 실행 권한 부여 및 실행

```bash
chmod +x recovering-restart.sh
./recovering-restart.sh
```

---
