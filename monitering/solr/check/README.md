# 🔍 Solr 상태 점검 스크립트 구성

이 디렉터리는 Solr 클러스터의 상태를 모니터링하고, 장애 여부를 판단하며, 반복 확인을 통해 일시적 오류와 실제 장애를 구분하는 스크립트 모음입니다.

---

## 📂 파일 구성

| 파일명                          | 설명                                                                 |
|--------------------------------|----------------------------------------------------------------------|
| `solr_config-061069.conf`      | `.61.69` 웹 Solr의 설정 파일                                  |
| `solr_config-041069.conf`      | `41.69` 시스템 Solr의 설정 파일                              |
| `solrweb_status-061069.sh`     | 웹 Solr 상태 점검 스크립트 (cron에 등록)                             |
| `solrsys_status-041069.sh`     | 시스템 Solr 상태 점검 스크립트 (cron에 등록)                         |
| `solr_status_retry.sh`         | 장애 발생 시 공통으로 사용되는 **재확인 스크립트**                   |

---

## ✅ 설정 파일 구조

Solr의 IP, 포트, 클러스터 상태 URL은 각 서버별 `.conf` 파일로 분리되어 관리됩니다.

예: `solr_config-061069.conf`

```bash
SOLR_HOST=".61.69"
SOLR_PORT="8983"
SOLR_URL="http://$SOLR_HOST:$SOLR_PORT/solr/admin/collections?action=CLUSTERSTATUS"
````

모든 점검 스크립트는 다음 방식으로 설정을 로드합니다:

```bash
CONFIG_FILE="$(dirname "$0")/solr_config-061069.conf"
source "$CONFIG_FILE"
```

---

## 🖥️ 점검 스크립트 실행 흐름

1. `solrweb_status-061069.sh` 또는 `solrsys_status-041069.sh`가 **매 1분마다 cron에서 실행**됨
2. Solr 상태를 점검하여 `recovering`, `down`, `inactive` 등의 상태를 감지
3. 장애 감지 시, 공통 스크립트 `solr_status_retry.sh`를 호출하며 설정 파일 경로를 인자로 넘김

---

## 🔁 Retry 로직 동작 방식

`solr_status_retry.sh`는 다음과 같은 로직으로 작동합니다:

| 실행 횟수  | 상태 감지 시 행동                                           |
| ------ | ---------------------------------------------------- |
| 1회차    | 장애 감지 → `/tmp/down_<host>.log`에 `1` 기록, 60초 대기 후 재시도 |
| 2회차    | 장애 감지 → `2` 기록, 60초 대기 후 재시도                         |
| 3회차    | 장애 감지 → `3` 기록, 알림 메일 발송, 종료                         |
| 중간에 정상 | `down.log` 초기화 (`0`) 및 복구 로그 남김                      |

### 로그 파일 예시

* `/tmp/down_61.69.log`
* `/tmp/down_41.69.log`

---

## 🛠️ 크론탭 등록 예시

```cron
* * * * * /home/sysadmin/check/solrweb_status-061069.sh >> /var/log/solr_status_web.log 2>&1
* * * * * /home/sysadmin/check/solrsys_status-041069.sh >> /var/log/solr_status_sys.log 2>&1
```

---

## 🧩 확장 구조 예시

```
howto/monitoring/solr/check/scripts/
├── solr_config-061069.conf
├── solr_config-041069.conf
├── solr_status_retry.sh
├── solrweb_status-061069.sh
├── solrsys_status-041069.sh
└── README.md
```

---

## 📬 문의

* 장애 메일 수신자: `@qubitsec.com`
* 로그는 `logger -t solr_check`로 로컬 syslog에 기록됩니다.

---
