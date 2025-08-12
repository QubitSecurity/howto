테스트를 위해 의도적으로 Solr core 상태를 `"recovering"`으로 조작하고 싶으시다면,
`solrweb_status-061069.sh`에서 JSON 응답을 파싱하기 전에 **임의로 조작된 값을 넣는 방식이 가장 안전하고 효과적**입니다.

---

## ✅ 추천 방식: `response` 변수에 가짜 Recovering 상태 주입

`curl`로 응답 받은 `response` 바로 아래에 아래 코드를 삽입하세요:

```bash
# === 테스트용: 강제로 상태를 recovering으로 변경 (테스트 끝나면 제거할 것!) ===
# 원본 response 변수에 recovering 상태를 포함시켜 테스트
response='{
  "cluster": {
    "collections": {
      "test_collection": {
        "shards": {
          "shard1": {
            "replicas": {
              "core_node1": {
                "core": "core_node1",
                "state": "recovering",
                "node_name": "solr1:8983",
                "leader": "false"
              }
            }
          }
        }
      }
    }
  }
}'
```

---

### 🔁 삽입 위치

`response=$(curl ...)` 바로 아래:

```bash
response=$(curl -s --max-time 5 "$SOLR_URL")
if [ $? -ne 0 ] || [ -z "$response" ]; then
  ...
fi

# ⬇️ 여기에 삽입
response='{
  "cluster": {
    "collections": {
      "test_collection": {
        "shards": {
          "shard1": {
            "replicas": {
              "core_node1": {
                "core": "core_node1",
                "state": "recovering",
                "node_name": "solr1:8983",
                "leader": "false"
              }
            }
          }
        }
      }
    }
  }
}'
```

---

## ✅ 기대 결과

* `solrweb_status-061069.sh`는 recovering 상태를 감지하여 `solrweb_status_retry.sh`를 호출
* `solrweb_status_retry.sh`는 `/tmp/down_<host>.log`에 `1 → 2 → 3` 순으로 기록 후 메일 전송

---

## ✅ 테스트 종료 후 잊지 말고 제거

테스트가 끝나면 해당 `response='...'` 블록을 주석 처리하거나 삭제하세요.
실제 Solr 상태 확인이 안 됩니다.

---
