#!/usr/bin/env bash
# 공통 재시도 스크립트
# 사용법: solr_status_retry.sh <CONFIG_FILE> <CHECK_SCRIPT> <CHECK_NAME> "<ERROR_MSG>"
set -euo pipefail

CONFIG_FILE="${1:-}"; CHECK_SCRIPT="${2:-}"; CHECK_NAME_ARG="${3:-}"; ERROR_MSG="${4:-"unknown error"}"
if [[ -z "${CONFIG_FILE}" || -z "${CHECK_SCRIPT}" || -z "${CHECK_NAME_ARG}" ]]; then
  echo "[retry] invalid args. usage: $0 <CONFIG_FILE> <CHECK_SCRIPT> <CHECK_NAME> <ERROR_MSG>" >&2
  exit 2
fi

source "${CONFIG_FILE}"

LOG_TAG="${LOG_TAG:-solr_check}"
STATE_DIR="${STATE_DIR:-/tmp}"
SOLR_HOST_SAFE="${SOLR_HOST//[^A-Za-z0-9]/_}"
STATE_FILE="${STATE_DIR}/down_${SOLR_HOST_SAFE}_${CHECK_NAME_ARG}.log"

read -r COUNT < <( ( [[ -f "${STATE_FILE}" ]] && cat "${STATE_FILE}" ) || echo 0 )
COUNT=$(( COUNT + 1 ))
echo "${COUNT}" > "${STATE_FILE}"

logger -t "${LOG_TAG}" "[${CHECK_NAME_ARG}] failure #${COUNT} on ${SOLR_HOST} : ${ERROR_MSG}"

# 1~2회차: 60초 대기 후 재확인
if [[ "${COUNT}" -lt 3 ]]; then
  sleep 60
  # 재확인은 --no-retry 플래그로 재귀 방지
  if bash "${CHECK_SCRIPT}" --no-retry "${CONFIG_FILE}"; then
    echo "0" > "${STATE_FILE}"
    logger -t "${LOG_TAG}" "[${CHECK_NAME_ARG}] recovered on ${SOLR_HOST} after retry"
    exit 0
  else
    exit 1
  fi
fi

# 3회차: 알림 발송 후 종료(다음 성공 때까지 STATE_FILE은 3 유지)
SUBJECT="[ALERT] ${CHECK_NAME_ARG} failure on ${SOLR_HOST}"
BODY="Host: ${SOLR_HOST}
Check: ${CHECK_NAME_ARG}
Error: ${ERROR_MSG}
Time:  $(date -u +"%Y-%m-%dT%H:%M:%SZ")"

if [[ -n "${ALERT_EMAILS:-}" ]]; then
  # mailx / mail 명령 존재 시 사용
  if command -v mail >/dev/null 2>&1; then
    echo "${BODY}" | mail -s "${SUBJECT}" "${ALERT_EMAILS}"
  elif command -v sendmail >/dev/null 2>&1; then
    {
      echo "Subject: ${SUBJECT}"
      echo "To: ${ALERT_EMAILS}"
      echo
      echo "${BODY}"
    } | sendmail -t
  fi
fi

logger -t "${LOG_TAG}" "[${CHECK_NAME_ARG}] alert sent for ${SOLR_HOST}"
exit 2
