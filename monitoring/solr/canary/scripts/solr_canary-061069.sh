#!/usr/bin/env bash
# solr_canary-061069.sh — Quiet Canary (implicit router + /select 검증)
# 실패/복구 알림/연속 카운팅은 공통 모듈 solr_status_retry.sh 에 위임

set -euo pipefail

DEBUG="${DEBUG:-0}"
HARD_TIMEOUT_SEC="${HARD_TIMEOUT_SEC:-60}"
if command -v timeout >/dev/null 2>&1; then
  if [[ "${_CANARY_WRAP:-0}" != "1" ]]; then
    export _CANARY_WRAP=1
    exec timeout --preserve-status "${HARD_TIMEOUT_SEC}" bash "$0" "$@"
  fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${1:-${SCRIPT_DIR}/solr_config-061069.conf}"
[[ -f "${CONFIG_FILE}" ]] || { echo "config not found: ${CONFIG_FILE}" >&2; exit 2; }
# shellcheck disable=SC1090
source "${CONFIG_FILE}"

# 기본값
LOG_TAG="${LOG_TAG:-solr_check}"
CHECK_NAME="${CHECK_NAME:-canary_write}"
TIMEOUT_SEC="${TIMEOUT_SEC:-10}"
CURL_INSECURE="${CURL_INSECURE:-false}"
COMMIT_WITHIN_MS="${COMMIT_WITHIN_MS:-2000}"
MIN_RF="${MIN_RF:-1}"
READ_VERIFY_RETRIES="${READ_VERIFY_RETRIES:-3}"
READ_VERIFY_SLEEP_SEC="${READ_VERIFY_SLEEP_SEC:-1}"
USE_TS_FIELD="${USE_TS_FIELD:-false}"

UNIQUE_KEY_FIELD="${UNIQUE_KEY_FIELD:-id}"
ROUTE_FIELD="${ROUTE_FIELD:-}"
ROUTE_VALUE="${ROUTE_VALUE:-}"

SOLR_UPDATE_URL="${SOLR_UPDATE_URL:-${SOLR_BASE}/${COLLECTION_CANARY}/update/json/docs}"
SOLR_SELECT_URL="${SOLR_BASE}/${COLLECTION_CANARY}/select"
SOLR_ADMIN_URL="${SOLR_SCHEME}://${SOLR_HOST}:${SOLR_PORT}/solr/admin"

# curl 옵션
declare -a CURL_VERBOSE_FLAG=(); [[ "${DEBUG}" == "1" ]] && CURL_VERBOSE_FLAG=(-v)
declare -a auth_args=()
if [[ -z "${SOLR_BASIC_AUTH:-}" && -n "${SOLR_BASIC_AUTH_FILE:-}" && -f "${SOLR_BASIC_AUTH_FILE}" ]]; then
  SOLR_BASIC_AUTH="$(<"${SOLR_BASIC_AUTH_FILE}")"
fi
[[ -n "${SOLR_BASIC_AUTH:-}" ]] && auth_args=(-u "${SOLR_BASIC_AUTH}")
declare -a curl_common=(-sS --max-time "${TIMEOUT_SEC}" --connect-timeout 3)
if curl --fail-with-body --version >/dev/null 2>&1; then curl_common+=(--fail-with-body); fi
[[ "${CURL_INSECURE}" == "true" ]] && curl_common+=(-k)

# ===== UPDATE =====
DOC_ID="canary-$(hostname -s)-$(date +%s)-$RANDOM"
UNIQ_FIELD="${UNIQUE_KEY_FIELD}"

if [[ -n "${ROUTE_FIELD}" && -n "${ROUTE_VALUE}" ]]; then
  if [[ "${USE_TS_FIELD}" == "true" ]]; then
    PAYLOAD=$(printf '[{"%s":"%s","%s":"%s","ts_dt":"NOW"}]' "${UNIQ_FIELD}" "${DOC_ID}" "${ROUTE_FIELD}" "${ROUTE_VALUE}")
  else
    PAYLOAD=$(printf '[{"%s":"%s","%s":"%s"}]' "${UNIQ_FIELD}" "${DOC_ID}" "${ROUTE_FIELD}" "${ROUTE_VALUE}")
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

COLL_HINT=""
if [[ "${HTTP_CODE:-}" == "404" ]]; then
  LIST_OUT="$(mktemp)"
  curl -sS --connect-timeout 3 --max-time 8 \
    "${SOLR_ADMIN_URL}/collections?action=LIST&wt=json" -o "${LIST_OUT}" || true
  HAVE=$(jq -r --arg c "${COLLECTION_CANARY}" '.collections[]? | select(.==$c)' "${LIST_OUT}" 2>/dev/null || true)
  [[ -z "${HAVE:-}" ]] && COLL_HINT="Collection '${COLLECTION_CANARY}' not found."
  rm -f "${LIST_OUT}" || true
fi

FAIL_REASON=""
if [[ -z "${HTTP_CODE}" || "${HTTP_CODE}" == "000" || "${HTTP_CODE}" -ne 200 || "${STATUS}" -ne 0 ]]; then
  FAIL_REASON="UPDATE http=${HTTP_CODE:-empty} status=${STATUS} rf=${RF} err='${ERR_TXT}'"
  [[ -n "${COLL_HINT}" ]] && FAIL_REASON="${FAIL_REASON} | ${COLL_HINT}"
fi

# ===== VERIFY (/select) =====
if [[ -z "${FAIL_REASON}" ]]; then
  FOUND="false"
  for ((i=1; i<=READ_VERIFY_RETRIES; i++)); do
    GET_RESP="$(mktemp)"
    HTTP_GET=$(
      curl ${CURL_VERBOSE_FLAG[@]+"${CURL_VERBOSE_FLAG[@]}"} "${curl_common[@]}" \
        -w '%{http_code}' -o "${GET_RESP}" \
        ${auth_args[@]+"${auth_args[@]}"} \
        "${SOLR_SELECT_URL}?q=${UNIQ_FIELD}%3A%22${DOC_ID}%22&rows=1&fl=${UNIQ_FIELD}&wt=json" || true
    )
    GOT_ID=$(jq -r --arg k "${UNIQ_FIELD}" '.response.docs[0][$k] // empty' "${GET_RESP}" 2>/dev/null || true)
    rm -f "${GET_RESP}" || true
    if [[ "${HTTP_GET}" == "200" && "${GOT_ID}" == "${DOC_ID}" ]]; then FOUND="true"; break; fi
    sleep "${READ_VERIFY_RETRIES}"
  done
  [[ "${FOUND}" != "true" ]] && FAIL_REASON="VERIFY http=${HTTP_GET:-empty} got='${GOT_ID:-none}'"
fi

# ===== 공통 모듈 호출 =====
RETRY_SH="${SCRIPT_DIR}/solr_status_retry.sh"

if [[ -n "${FAIL_REASON}" ]]; then
  # 실패: 공통 모듈에 FAIL 보고 → 모듈이 N연속 정책/메일 처리
  bash "${RETRY_SH}" "${CONFIG_FILE}" FAIL "${CHECK_NAME}" "${FAIL_REASON}" "${COLLECTION_CANARY}" || true
  exit 1
else
  # 성공: 공통 모듈에 RECOVERY 보고 → 필요 시 복구 메일
  bash "${RETRY_SH}" "${CONFIG_FILE}" RECOVERY "${CHECK_NAME}" "${COLLECTION_CANARY}" || true
  exit 0
fi
