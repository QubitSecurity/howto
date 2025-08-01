좋습니다!
`SOLR_HOST`, `SOLR_PORT`, `SOLR_URL` 같은 설정값을 별도의 설정 파일로 분리하고,
두 스크립트에서 이를 **`source` 명령으로 불러오는 방식**으로 구성하겠습니다.

---

## ✅ 1. 공통 설정 파일 작성 (`solr_config_061069.conf`)

```bash
# solr_config_061069.conf

SOLR_HOST=".61.69"
SOLR_PORT="8983"
SOLR_URL="http://$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=CLUSTERSTATUS"
```

> 이 파일은 두 스크립트와 동일한 디렉터리에 두는 것이 가장 간편합니다.
> 그렇지 않으면 절대경로 지정 필요.

---

## ✅ 2. `solrweb_status-061069.sh` 수정

```bash
#!/bin/bash

# 공통 설정 불러오기
source "$(dirname "$0")/solr_config_061069.conf"

LOG_TAG="solr_check"
CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")

# 이하 기존 코드 동일...
```

---

## ✅ 3. `solrweb_status_retry.sh` 수정

```bash
#!/bin/bash

# 공통 설정 불러오기
source "$(dirname "$0")/solr_config_061069.conf"

LOG_TAG="solr_check"
CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")

DOWN_LOG="/tmp/down_${SOLR_HOST}.log"

# 이하 기존 코드 동일...
```

---

## ✅ 구조 요약

```
/opt/solr-monitor/
├── solrweb_status-061069.sh
├── solr_status_retry.sh
└── solr_config-061069.conf  ← 공통 설정 파일
```

---

## ✅ 장점

| 항목      | 설명                                           |
| ------- | -------------------------------------------- |
| 🔄 재사용성 | 여러 스크립트에서 동일 설정을 공유                          |
| ⚙️ 유지보수 | IP나 포트 변경 시 하나의 파일만 수정                       |
| 🔧 확장성  | 여러 서버 모니터링 시 `solr_config_<host>.conf` 분리 가능 |

---

