#!/usr/bin/env bash
# solr_status_retry.sh — 공통 연속 실패/복구 알림 모듈
# 사용:
#   FAIL    : solr_status_retry.sh <CONFIG_FILE> FAIL <CHECK_NAME> "<FAIL_REASON>" [<COLLECTION>]
#   RECOVERY: solr_status_retry.sh <CONFIG_FILE> RECOVERY <CHECK_NAME> [<COLLECTION>]
#
# 특징:
#  - 연속 실패 카운트 저장: /tmp/retry_<host>_<port>_<collection>_<check>.state
#  - ALERT_ON_CONSECUTIVE (기본 3) 달성 시 첫 Alert, 이후 FAIL_NOTIFY_EVERY 주기로 재알림
#  - 복구 시 1회 Recovery 메일
#  - syslog(LOG_TAG)에는 상태 변화만 1줄 기록
#  - ko/en 메일 템플릿 지원: EMAIL_LOCALE=ko|en

set -euo pipefail

CONFIG_FILE="${1:-}"; ACTION="${2:-}"; CHECK_NAME="${3:-}"
[[ -z "${CONFIG_FILE}" || -z "${ACTION}" || -z "${CHECK_NAME}" ]] && {
  echo "Usage: $0 <CONFIG_FILE> FAIL <CHECK_NAME> \"<FAIL_REASON>\" [<COLLECTION>]" >&2
  echo "       $0 <CONFIG_FILE> RECOVERY <CHECK_NAME> [<COLLECTION>]" >&2
  exit 2
}
FAIL_REASON="${4:-}"
COLLECTION="${5:-${COLLECTION_CANARY:-unknown}}"

# 설정 로드
# shellcheck disable=SC1090
source "${CONFIG_FILE}"

# 기본값 보정
LOG_TAG="${LOG_TAG:-solr_check}"
STATE_DIR="${STATE_DIR:-/tmp}"
ALERT_EMAILS="${ALERT_EMAILS:-}"
ALERT_ON_CONSECUTIVE="${ALERT_ON_CONSECUTIVE:-3}"
FAIL_NOTIFY_EVERY="${FAIL_NOTIFY_EVERY:-3}"
EMAIL_LOCALE="${EMAIL_LOCALE:-ko}"

HOST_LABEL="${SOLR_HOST:-unknown}:${SOLR_PORT:-unknown}"

# 상태 파일 키
SAFE(){
  echo -n "$1" | tr -c 'A-Za-z0-9' '_'
}
KEY="retry_$(SAFE "${SOLR_HOST:-h}")_$(SAFE "${SOLR_PORT:-p}")_$(SAFE "${COLLECTION}")_$(SAFE "${CHECK_NAME}")"
STATE_FILE="${STATE_DIR}/${KEY}.state"   # 포맷: OK/FAIL,카운트,타임스탬프
NOW_TS="$(date '+%F %T%z')"

log(){ logger -t "${LOG_TAG}" "$*"; }
send_mail(){
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
    log "WARN [${CHECK_NAME}] mail command not found; cannot notify"
  fi
}

# 상태 로드
PREV_STATUS="INIT"; PREV_COUNT=0
if [[ -f "${STATE_FILE}" ]]; then
  IFS=',' read -r PREV_STATUS PREV_COUNT _ < "${STATE_FILE}" || true
fi

make_mail(){
  local mode="$1"   # ALERT / ALERT_REPEAT / RECOVERY
  local more="$2"
  local subject body
  if [[ "${EMAIL_LOCALE}" == "ko" ]]; then
    case "${mode}" in
      ALERT)
        subject="[ALERT] Solr ${ALERT_ON_CONSECUTIVE}회 연속 장애 감지"
        body="대상: ${HOST_LABEL}
컬렉션: ${COLLECTION}

시간: ${NOW_TS}

장애 상세:
- ${more}"
        ;;
      ALERT_REPEAT)
        subject="[ALERT] Solr 장애 지속 x${PREV_COUNT}"
        body="대상: ${HOST_LABEL}
컬렉션: ${COLLECTION}

시간: ${NOW_TS}
지속: ${PREV_COUNT}회

장애 상세:
- ${more}"
        ;;
      RECOVERY)
        subject="[RECOVERY] Solr 쓰기 경로 정상화"
        body="대상: ${HOST_LABEL}
컬렉션: ${COLLECTION}

시간: ${NOW_TS}

복구 상세:
- ${more}"
        ;;
    esac
  else
    case "${mode}" in
      ALERT)
        subject="[ALERT] Solr failure detected ${ALERT_ON_CONSECUTIVE}x"
        body="Target: ${HOST_LABEL}
Collection: ${COLLECTION}

Time: ${NOW_TS}

Detail:
- ${more}"
        ;;
      ALERT_REPEAT)
        subject="[ALERT] Solr failure persists x${PREV_COUNT}"
        body="Target: ${HOST_LABEL}
Collection: ${COLLECTION}

Time: ${NOW_TS}
Count: ${PREV_COUNT}

Detail:
- ${more}"
        ;;
      RECOVERY)
        subject="[RECOVERY] Solr write path recovered"
        body="Target: ${HOST_LABEL}
Collection: ${COLLECTION}

Time: ${NOW_TS}

Recovered:
- ${more}"
        ;;
    esac
  fi
  echo "${subject}"; echo "-----"; echo "${body}"
}

case "${ACTION}" in
  FAIL)
    # 처음 FAIL 진입
    if [[ "${PREV_STATUS}" != "FAIL" ]]; then
      PREV_COUNT=1
      echo "FAIL,${PREV_COUNT},${NOW_TS}" > "${STATE_FILE}"
      log "ERROR [${CHECK_NAME}] FAIL #${PREV_COUNT} on ${HOST_LABEL} (${COLLECTION}): ${FAIL_REASON}"
      # N==1인 환경만 즉시 알림
      if (( ALERT_ON_CONSECUTIVE == 1 )); then
        IFS=$'\n' read -r SUBJ _ BODY < <(make_mail "ALERT" "${FAIL_REASON}")
        send_mail "${SUBJ}" "${BODY}"
      fi
      exit 1
    fi
    # 지속 FAIL
    PREV_COUNT=$(( PREV_COUNT + 1 ))
    echo "FAIL,${PREV_COUNT},${NOW_TS}" > "${STATE_FILE}"
    log "ERROR [${CHECK_NAME}] FAIL repeat #${PREV_COUNT} on ${HOST_LABEL} (${COLLECTION}): ${FAIL_REASON}"

    if (( PREV_COUNT == ALERT_ON_CONSECUTIVE )); then
      IFS=$'\n' read -r SUBJ _ BODY < <(make_mail "ALERT" "${FAIL_REASON}")
      send_mail "${SUBJ}" "${BODY}"
    elif (( PREV_COUNT > ALERT_ON_CONSECUTIVE )) && (( PREV_COUNT % FAIL_NOTIFY_EVERY == 0 )); then
      IFS=$'\n' read -r SUBJ _ BODY < <(make_mail "ALERT_REPEAT" "${FAIL_REASON}")
      send_mail "${SUBJ}" "${BODY}"
    fi
    exit 1
    ;;
  RECOVERY)
    # FAIL → OK 로 전환 시에만 메일
    if [[ "${PREV_STATUS}" == "FAIL" ]]; then
      echo "OK,0,${NOW_TS}" > "${STATE_FILE}"
      log "INFO  [${CHECK_NAME}] RECOVERED on ${HOST_LABEL} (${COLLECTION})"
      IFS=$'\n' read -r SUBJ _ BODY < <(make_mail "RECOVERY" "${FAIL_REASON}")
      send_mail "${SUBJ}" "${BODY}"
    else
      echo "OK,0,${NOW_TS}" > "${STATE_FILE}"
      # 조용히 성공 기록만
    fi
    exit 0
    ;;
  *)
    echo "Unknown ACTION: ${ACTION}" >&2
    exit 2
    ;;
esac
