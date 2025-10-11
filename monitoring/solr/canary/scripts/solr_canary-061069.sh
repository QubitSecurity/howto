#!/usr/bin/env bash
# Canary 쓰기-읽기 체크 (웹 Solr)
# 사용법:
#   1) 일반 실행(cron):   ./solr_canary-061069.sh
#   2) 재확인 실행용:      ./solr_canary-061069.sh --no-retry <CONFIG_FILE>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_CONFIG="${SCRIPT_DIR}/solr_config-061069.conf"

NO_RETRY="false"
if [[ "${1:-}" == "--no-retry" ]]; then
  NO_RETRY="true"
  shift
fi

CONFIG_FILE="${1:-$DEFAULT_CONFIG}"
source "${CONFIG_FILE}"

LOG_TAG="${LOG_TAG:-solr_check}"
STATE_DIR="${STATE_DIR:-/tmp}"
CHECK_NAME="${CHECK_NAME:-canary_write}"
SOLR_HOST_SAFE="${SOLR_HOST//[^A-Za-z0-9]/_}"
STATE_FILE="${STATE_DIR}/down_${SOLR_HOST_SAFE}_${CHECK_NAME}.log"

# jq 필수
if ! command -v jq >/dev/null 2>&1; then
  logger -t "${LOG_TAG}" "[${CHECK_NAME}] jq not found. please install jq"
  exit 2
fi

# curl 공통 옵션
auth_args=()
if [[ -n "${SOLR_BASIC_AUTH_FILE:-}" && -f "${SOLR_BASIC_AUTH_FILE}" ]]; then
  SOLR_BASIC_AUTH="$(<"${SOLR_BASIC_AUTH_FILE}")"
fi
if [[ -n "${SOLR_BASIC_AUTH:-}" ]]; then
  auth_args=(-u "${SOLR_BASIC_AUTH}")
fi

curl_common=(-sS --max-time "${TIMEOUT_SEC:-10}" --connect-timeout 3)
[[ "${CURL_INSECURE}" == "true" ]] && curl_common+=(-k)

# 성공 시 상태 파일 초기화
reset_state_ok() {
  echo "0" > "${STATE_FILE}"
}

# 실패 처리 + 재시도 호출
fail_and_maybe_retry() {
  local _msg="$1"
  logger -t "${LOG_TAG}" "[${CHECK_NAME}] FAIL on ${SOLR_HOST}: ${_msg}"
  if [[ "${NO_RETRY}" == "false" ]]; then
    bash "${SCRIPT_DIR}/solr_status_retry.sh" "${CONFIG_FILE}" "${BASH_SOURCE[0]}" "${CHECK_NAME}" "${_msg}" || true
  fi
  exit 1
}

# === 1) UPDATE: 문서 1건 쓰기 ===
DOC_ID="canary-$(hostname -s)-$(date +%s)-$RANDOM"
if [[ "${USE_TS_FIELD}" == "true" ]]; then
  PAYLOAD=$(printf '[{"id":"%s","ts_dt":"NOW"}]' "${DOC_ID}")
else
  PAYLOAD=$(printf '[{"id":"%s"}]' "${DOC_ID}")
fi

UPD_RESP="$(mktemp)"; trap 'rm -f "${UPD_RESP}"' EXIT
HTTP_CODE=$(curl "${curl_common[@]}" -w '%{http_code}' -o "${UPD_RESP}" \
  "${auth_args[@]}" -H 'Content-Type: application/json' \
  --data "${PAYLOAD}" \
  "${SOLR_UPDATE_URL}?commitWithin=${COMMIT_WITHIN_MS}&wt=json" ) || true

STATUS=$(jq -r '.responseHeader.status // 1' "${UPD_RESP}" 2>/dev/null || echo 1)
RF=$(jq -r '.responseHeader.rf // 0' "${UPD_RESP}" 2>/dev/null || echo 0)
if [[ "${HTTP_CODE}" -ne 200 || "${STATUS}" -ne 0 ]]; then
  ERR_TXT=$(jq -r '.error.msg // empty' "${UPD_RESP}" 2>/dev/null || true)
  fail_and_maybe_retry "update http=${HTTP_CODE} status=${STATUS} rf=${RF} err='${ERR_TXT}'"
fi
if [[ "${RF}" -lt "${MIN_RF}" ]]; then
  logger -t "${LOG_TAG}" "[${CHECK_NAME}] WARN: rf=${RF} < MIN_RF=${MIN_RF} on ${SOLR_HOST}"
fi

# === 2) GET: 쓰기 확인(최대 N회 재시도) ===
FOUND="false"
for ((i=1; i<=READ_VERIFY_RETRIES; i++)); do
  GET_RESP="$(mktemp)"
  HTTP=$(curl "${curl_common[@]}" -w '%{http_code}' -o "${GET_RESP}" \
    "${auth_args[@]}" "${SOLR_GET_URL}?id=${DOC_ID}&wt=json") || true
  GOT_ID=$(jq -r '.doc.id // empty' "${GET_RESP}" 2>/dev/null || true)
  rm -f "${GET_RESP}"
  if [[ "${HTTP}" -eq 200 && "${GOT_ID}" == "${DOC_ID}" ]]; then
    FOUND="true"; break
  fi
  sleep "${READ_VERIFY_SLEEP_SEC}"
done

if [[ "${FOUND}" != "true" ]]; then
  fail_and_maybe_retry "verify get failed for id=${DOC_ID} after ${READ_VERIFY_RETRIES} tries"
fi

# === 3) (선택) 오래된 canary 청소 ===
if [[ "${ENABLE_CLEANUP}" == "true" && "${USE_TS_FIELD}" == "true" && "$(date +%M)" == "${CLEANUP_AT_MINUTE}" ]]; then
  UNIT=$([[ "${CLEANUP_DAYS}" -eq 1 ]] && echo "DAY" || echo "DAYS")
  DEL_PAYLOAD=$(printf '{"delete":{"query":"ts_dt:[* TO NOW-%s%s/DAY]"}, "commit": true}' "${CLEANUP_DAYS}" "${UNIT}")
  curl "${curl_common[@]}" -o /dev/null "${auth_args[@]}" -H 'Content-Type: application/json' \
    --data "${DEL_PAYLOAD}" "${SOLR_UPDATE_URL}?wt=json" || true
fi

# === OK ===
reset_state_ok
logger -t "${LOG_TAG}" "[${CHECK_NAME}] OK on ${SOLR_HOST} id=${DOC_ID} rf=${RF} commitWithin=${COMMIT_WITHIN_MS}ms"
exit 0
