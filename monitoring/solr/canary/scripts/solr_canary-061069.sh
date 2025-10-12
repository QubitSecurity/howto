#!/usr/bin/env bash
# solr_canary-061069.sh — Production Quiet Canary (implicit router & weblog 컬렉션 대응)
# - 정상 시 무소음(옵션 하트비트만), 실패/복구 시 syslog + 메일 알림
# - uniqueKey/conf(UNIQUE_KEY_FIELD) 사용(documentId 등)
# - implicit field-router(shardId 등) 쓰기 지원(ROUTE_FIELD/ROUTE_VALUE 주입)
# - 검증은 /select 기반(분산 검색)으로 라우팅 힌트 없이도 견고
# - 프록시/NO_PROXY는 변경하지 않음(환경에 따름)
#
# 크론(무소음):  * * * * * /path/solr_canary-061069.sh >/dev/null 2>&1
# 요구: 동일 디렉터리에 solr_config-061069.conf 존재

set -euo pipefail

# ===== 실행 제어 / 디버그 =====
DEBUG="${DEBUG:-0}"                          # 1이면 일부 진행 로그 echo
HARD_TIMEOUT_SEC="${HARD_TIMEOUT_SEC:-60}"   # 전체 하드 타임아웃
if command -v timeout >/dev/null 2>&1; then
  if [[ "${_CANARY_WRAP:-0}" != "1" ]]; then
    export _CANARY_WRAP=1
    exec timeout --preserve-status "${HARD_TIMEOUT_SEC}" bash "$0" "$@"
  fi
fi

# ===== 경로/설정 로드 =====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${1:-${SCRIPT_DIR}/solr_config-061069.conf}"
[[ -f "${CONFIG_FILE}" ]] || { echo "config not found: ${CONFIG_FILE}" >&2; exit 2; }
# shellcheck disable=SC1090
source "${CONFIG_FILE}"

# ===== 기본값 보정 =====
LOG_TAG="${LOG_TAG:-solr_check}"
STATE_DIR="${STATE_DIR:-/tmp}"
CHECK_NAME="${CHECK_NAME:-canary_write}"
TIMEOUT_SEC="${TIMEOUT_SEC:-10}"
CURL_INSECURE="${CURL_INSECURE:-false}"
COMMIT_WITHIN_MS="${COMMIT_WITHIN_MS:-2000}"
MIN_RF="${MIN_RF:-1}"
READ_VERIFY_RETRIES="${READ_VERIFY_RETRIES:-3}"
READ_VERIFY_SLEEP_SEC="${READ_VERIFY_SLEEP_SEC:-1}"
USE_TS_FIELD="${USE_TS_FIELD:-false}"
ENABLE_CLEANUP="${ENABLE_CLEANUP:-false}"
CLEANUP_DAYS="${CLEANUP_DAYS:-1}"
CLEANUP_AT_MINUTE="${CLEANUP_AT_MINUTE:-00}"

UNIQUE_KEY_FIELD="${UNIQUE_KEY_FIELD:-id}"       # 예: documentId
ROUTE_FIELD="${ROUTE_FIELD:-}"                   # 예: shardId
ROUTE_VALUE="${ROUTE_VALUE:-}"                   # 예: shard10

# URL(conf에서 지정 권장; raw JSON 배열은 /update/json/docs 사용)
SOLR_UPDATE_URL="${SOLR_UPDATE_URL:-${SOLR_BASE}/${COLLECTION_CANARY}/update/json/docs}"
SOLR_GET_URL="${SOLR_GET_URL:-${SOLR_BASE}/${COLLECTION_CANARY}/get}" # (검증은 /select 사용)
SOLR_ADMIN_URL="${SOLR_ADMIN_URL:-${SOLR_SCHEME}://${SOLR_HOST}:${SOLR_PORT}/solr/admin}"

ALERT_EMAILS="${ALERT_EMAILS:-}"
FAIL_NOTIFY_EVERY="${FAIL_NOTIFY_EVERY:-3}"
HEARTBEAT_MINUTE="${HEARTBEAT_MINUTE:-}"

SOLR_HOST_SAFE="${SOLR_HOST//[^A-Za-z0-9]/_}"
STATE_FILE="${STATE_DIR}/canary_${SOLR_HOST_SAFE}_${CHECK_NAME}.state"  # 포맷: OK/FAIL,카운트,시각

# ===== 유틸 =====
_ts(){ date '+%F %T%z'; }
_qecho(){ [[ "${DEBUG}" == "1" ]] && echo "$*"; }
_log_change(){ logger -t "${LOG_TAG}" "$*"; _qecho "$*"; }
_send_mail(){
  local subject="$1"; shift
  local body="$*"
  [[ -z "${ALERT_EMAILS}" ]] && return 0
  if command -v mail >/dev/null 2>&1; then
    printf "%s\n" "${body}" | mail -s "${subject}" "${ALERT_EMAILS}"
  elif command -v sendmail >/dev/null 2>&1; then
    {
      printf "Subject: %s\n" "${subject}"
      printf "To: %s\n\n" "${ALERT_EMAILS}"
      printf "%s\n" "${body}"
    } | sendmail -t
  else
    _log_change "WARN [$(_ts)] [${CHECK_NAME}] mail command not found; cannot notify"
  fi
}

# ===== 전제 검사 =====
for bin in jq curl; do
  command -v "$bin" >/dev/null 2>&1 || { _log_change "ERROR [$(_ts)] [${CHECK_NAME}] $bin not found"; exit 2; }
done

# ===== CURL 옵션 =====
declare -a CURL_VERBOSE_FLAG=()
[[ "${DEBUG}" == "1" ]] && CURL_VERBOSE_FLAG=(-v)

declare -a auth_args=()
if [[ -z "${SOLR_BASIC_AUTH:-}" && -n "${SOLR_BASIC_AUTH_FILE:-}" && -f "${SOLR_BASIC_AUTH_FILE}" ]]; then
  SOLR_BASIC_AUTH="$(<"${SOLR_BASIC_AUTH_FILE}")"
fi
[[ -n "${SOLR_BASIC_AUTH:-}" ]] && auth_args=(-u "${SOLR_BASIC_AUTH}")

declare -a curl_common=(-sS --max-time "${TIMEOUT_SEC}" --connect-timeout 3)
if curl --fail-with-body --version >/dev/null 2>&1; then
  curl_common+=(--fail-with-body)
fi
[[ "${CURL_INSECURE}" == "true" ]] && curl_common+=(-k)

# ===== 상태 파일 로드 =====
PREV_STATUS="INIT"; PREV_COUNT=0
if [[ -f "${STATE_FILE}" ]]; then
  IFS=',' read -r PREV_STATUS PREV_COUNT _ < "${STATE_FILE}" || true
fi

# ===== UPDATE =====
DOC_ID="canary-$(hostname -s)-$(date +%s)-$RANDOM"
UNIQ_FIELD="${UNIQUE_KEY_FIELD}"

# payload: uniqueKey + (옵션) route 필드 + (옵션) ts_dt
if [[ -n "${ROUTE_FIELD}" && -n "${ROUTE_VALUE}" ]]; then
  if [[ "${USE_TS_FIELD}" == "true" ]]; then
    PAYLOAD=$(printf '[{"%s":"%s","%s":"%s","ts_dt":"NOW"}]' \
      "${UNIQ_FIELD}" "${DOC_ID}" "${ROUTE_FIELD}" "${ROUTE_VALUE}")
  else
    PAYLOAD=$(printf '[{"%s":"%s","%s":"%s"}]' \
      "${UNIQ_FIELD}" "${DOC_ID}" "${ROUTE_FIELD}" "${ROUTE_VALUE}")
  fi
else
  if [[ "${USE_TS_FIELD}" == "true" ]]; then
    PAYLOAD=$(printf '[{"%s":"%s","ts_dt":"NOW"}]' "${UNIQ_FIELD}" "${DOC_ID}")
  else
    PAYLOAD=$(printf '[{"%s":"%s"}]' "${UNIQ_FIELD}" "${DOC_ID}")
  fi
fi

UPD_RESP="$(mktemp)"; trap 'rm -f "${UPD_RESP}" 2>/dev/null || true' EXIT
HTTP_CODE=$(
  curl ${CURL_VERBOSE_FLAG[@]+"${CURL_VERBOSE_FLAG[@]}"} "${curl_common[@]}" \
    -w '%{http_code}' -o "${UPD_RESP}" \
    ${auth_args[@]+"${auth_args[@]}"} \
    -H 'Content-Type: application/json' \
    --data "${PAYLOAD}" \
    "${SOLR_UPDATE_URL}?commitWithin=${COMMIT_WITHIN_MS}&wt=json" || true
)
STATUS=$(jq -r '.responseHeader.status // 1' "${UPD_RESP}" 2>/dev/null || echo 1)
RF=$(jq -r '.responseHeader.rf // 0' "${UPD_RESP}" 2>/dev/null || echo 0)
ERR_TXT=$(jq -r '.error.msg // empty' "${UPD_RESP}" 2>/dev/null || true)

# 404 힌트(컬렉션 존재)
COLL_HINT=""
if [[ "${HTTP_CODE:-}" == "404" ]]; then
  LIST_OUT="$(mktemp)"
  curl -sS --connect-timeout 3 --max-time 8 \
    "${SOLR_ADMIN_URL}/collections?action=LIST&wt=json" -o "${LIST_OUT}" || true
  HAVE=$(jq -r --arg c "${COLLECTION_CANARY}" '.collections[]? | select(.==$c)' "${LIST_OUT}" 2>/dev/null || true)
  [[ -z "${HAVE:-}" ]] && COLL_HINT="Collection '${COLLECTION_CANARY}' not found (LIST)."
  rm -f "${LIST_OUT}" || true
fi

FAIL_REASON=""
if [[ -z "${HTTP_CODE}" || "${HTTP_CODE}" == "000" || "${HTTP_CODE}" -ne 200 || "${STATUS}" -ne 0 ]]; then
  FAIL_REASON="UPDATE failed http=${HTTP_CODE:-empty} status=${STATUS} rf=${RF} err='${ERR_TXT}'"
  [[ -n "${COLL_HINT}" ]] && FAIL_REASON="${FAIL_REASON} | ${COLL_HINT}"
fi

# ===== VERIFY (/select 기반, 견고) =====
if [[ -z "${FAIL_REASON}" ]]; then
  FOUND="false"
  for ((i=1; i<=READ_VERIFY_RETRIES; i++)); do
    GET_RESP="$(mktemp)"
    # q=uniqueKey:"DOC_ID", rows=1, fl=uniqueKey만
    HTTP_GET=$(
      curl ${CURL_VERBOSE_FLAG[@]+"${CURL_VERBOSE_FLAG[@]}"} "${curl_common[@]}" \
        -w '%{http_code}' -o "${GET_RESP}" \
        ${auth_args[@]+"${auth_args[@]}"} \
        "${SOLR_BASE}/${COLLECTION_CANARY}/select?q=${UNIQ_FIELD}%3A%22${DOC_ID}%22&rows=1&fl=${UNIQ_FIELD}&wt=json" || true
    )
    GOT_ID=$(jq -r --arg k "${UNIQ_FIELD}" '.response.docs[0][$k] // empty' "${GET_RESP}" 2>/dev/null || true)
    rm -f "${GET_RESP}" || true

    if [[ "${HTTP_GET}" == "200" && "${GOT_ID}" == "${DOC_ID}" ]]; then
      FOUND="true"; break
    fi
    sleep "${READ_VERIFY_SLEEP_SEC}"
  done
  [[ "${FOUND}" != "true" ]] && FAIL_REASON="VERIFY(SELECT) failed http=${HTTP_GET:-empty} got='${GOT_ID:-none}'"
fi

# ===== 청소(옵션; ts_dt 있을 때만) =====
if [[ -z "${FAIL_REASON}" && "${ENABLE_CLEANUP}" == "true" && "${USE_TS_FIELD}" == "true" && "$(date +%M)" == "${CLEANUP_AT_MINUTE}" ]]; then
  DAYS="${CLEANUP_DAYS}"; [[ "${DAYS}" -lt 1 ]] && DAYS=1
  CLEAN_PAY=$(printf '{"delete":{"query":"ts_dt:[* TO NOW-%sDAY/DAY]"},"commit":true}' "${DAYS}")
  curl -sS --connect-timeout 3 --max-time 8 \
    ${auth_args[@]+"${auth_args[@]}"} -H 'Content-Type: application/json' \
    --data "${CLEAN_PAY}" "${SOLR_UPDATE_URL}?wt=json" >/dev/null 2>&1 || true
fi

# ===== 상태/알림(저소음) =====
NOW_TS="$(_ts)"
if [[ -n "${FAIL_REASON}" ]]; then
  if [[ "${PREV_STATUS}" != "FAIL" ]]; then
    _log_change "ERROR [${NOW_TS}] [${CHECK_NAME}] ${FAIL_REASON}"
    BODY="Host: ${SOLR_HOST}:${SOLR_PORT}
Collection: ${COLLECTION_CANARY}
Check: ${CHECK_NAME}
Time:  ${NOW_TS}
${FAIL_REASON}

Response:
$(tail -c 2000 "${UPD_RESP}" 2>/dev/null || true)"
    _send_mail "[ALERT] Solr canary FAIL on ${SOLR_HOST}" "${BODY}"
    echo "FAIL,1,${NOW_TS}" > "${STATE_FILE}"
  else
    PREV_COUNT=$(( PREV_COUNT + 1 ))
    if (( PREV_COUNT % FAIL_NOTIFY_EVERY == 0 )); then
      _log_change "ERROR [${NOW_TS}] [${CHECK_NAME}] (repeat #${PREV_COUNT}) ${FAIL_REASON}"
      BODY="Host: ${SOLR_HOST}:${SOLR_PORT}
Collection: ${COLLECTION_CANARY}
Check: ${CHECK_NAME}
Time:  ${NOW_TS}
Repeat: ${PREV_COUNT}
${FAIL_REASON}"
      _send_mail "[ALERT] Solr canary FAIL x${PREV_COUNT} on ${SOLR_HOST}" "${BODY}"
    fi
    echo "FAIL,${PREV_COUNT},${NOW_TS}" > "${STATE_FILE}"
  fi
  exit 1
else
  if [[ "${PREV_STATUS}" == "FAIL" ]]; then
    MSG="RECOVERED http=${HTTP_CODE} rf=${RF} ${UNIQ_FIELD}=${DOC_ID}"
    _log_change "INFO  [${NOW_TS}] [${CHECK_NAME}] ${MSG}"
    _send_mail "[RECOVERY] Solr canary OK on ${SOLR_HOST}" "Host: ${SOLR_HOST}:${SOLR_PORT}
Collection: ${COLLECTION_CANARY}
Check: ${CHECK_NAME}
Time:  ${NOW_TS}
${MSG}"
  else
    if [[ -n "${HEARTBEAT_MINUTE}" && "$(date +%M)" == "${HEARTBEAT_MINUTE}" ]]; then
      _log_change "INFO  [${NOW_TS}] [${CHECK_NAME}] heartbeat http=${HTTP_CODE} rf=${RF}"
    fi
  fi
  echo "OK,0,${NOW_TS}" > "${STATE_FILE}"
fi

exit 0
