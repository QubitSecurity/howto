#!/bin/bash
# Simple Solr node health with per-node email alerts
# - Quiet mode(default): 실패 노드만 출력/메일, 마지막에 요약 1줄
# - Verbose: OK도 모두 출력
# Usage: ./solr_query_health-041069.sh [-q|--quiet] [-v|--verbose]
# Env override: QUIET=true|false

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/solr_config-041069.conf"
source "$CONFIG_FILE"

# ===== CLI / ENV =====
QUIET_DEFAULT=${QUIET:-true}
QUIET="$QUIET_DEFAULT"
for arg in "${@:-}"; do
  case "$arg" in
    -q|--quiet)   QUIET=true ;;
    -v|--verbose) QUIET=false ;;
  esac
done

CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")

# Defaults (in case some are missing in conf)
SOLR_PROTO="${SOLR_PROTO:-http}"
SOLR_HOST="${SOLR_HOST:-127.0.0.1}"
SOLR_PORT="${SOLR_PORT:-8983}"
SOLR_URL="${SOLR_URL:-${SOLR_PROTO}://${SOLR_HOST}:${SOLR_PORT}/solr/admin/collections?action=CLUSTERSTATUS&wt=json}"
SOLR_CONNECT_TIMEOUT="${SOLR_CONNECT_TIMEOUT:-2}"
SOLR_TIMEOUT="${SOLR_TIMEOUT:-10}"
SOLR_COLLECTIONS="${SOLR_COLLECTIONS:-syslog}"
SOLR_QUERY="${SOLR_QUERY:-*:*}"
SOLR_TIME_ALLOWED_MS="${SOLR_TIME_ALLOWED_MS:-4000}"
SOLR_SSL_VERIFY="${SOLR_SSL_VERIFY:-true}"
LOG_TAG="${LOG_TAG:-solr_node_check}"
LOG_FACILITY="${LOG_FACILITY:-local0}"
ALERT_EMAILS="${ALERT_EMAILS:-}"

# first collection only
read -r -a _COLS <<<"$(echo "$SOLR_COLLECTIONS" | tr ',;' ' ')"
COL="${_COLS[0]}"

if ! command -v jq >/dev/null 2>&1; then
  echo "$CURRENT_TIME | CRITICAL: jq not found"
  logger -t "$LOG_TAG" -p ${LOG_FACILITY}.err "CRITICAL: jq not found"
  exit 2
fi

# curl base opts
CURL_OPTS=(-sS --connect-timeout "$SOLR_CONNECT_TIMEOUT" --max-time "$SOLR_TIMEOUT")
[ "$SOLR_SSL_VERIFY" = "false" ] && CURL_OPTS+=(-k)
[ -n "${SOLR_BASIC_AUTH_USER:-}" ] && CURL_OPTS+=(-u "${SOLR_BASIC_AUTH_USER}:${SOLR_BASIC_AUTH_PASS:-}")
[ -n "${SOLR_BEARER_TOKEN:-}" ] && CURL_OPTS+=(-H "Authorization: Bearer ${SOLR_BEARER_TOKEN}")

send_alert_mail() {
  local subject="$1" body="$2"
  [ -z "$ALERT_EMAILS" ] && return 0
  if ! command -v mail >/dev/null 2>&1; then
    logger -t "$LOG_TAG" -p ${LOG_FACILITY}.warning "mail command not found; subject=$subject"
    return 0
  fi
  IFS=',' read -r -a RECIPS <<<"$ALERT_EMAILS"
  for to in "${RECIPS[@]}"; do
    echo "$body" | mail -s "$subject" "$to"
  done
}

# 1) CLUSTERSTATUS
CS_JSON="$(curl "${CURL_OPTS[@]}" "$SOLR_URL" || true)"
if [ -z "$CS_JSON" ] || ! jq . >/dev/null 2>&1 <<<"$CS_JSON"; then
  msg="CRITICAL: failed to get CLUSTERSTATUS ($SOLR_HOST:$SOLR_PORT)"
  echo "$CURRENT_TIME | $msg"
  logger -t "$LOG_TAG" -p ${LOG_FACILITY}.err "$msg"
  send_alert_mail "[ALERT] Solr CLUSTERSTATUS failure ($SOLR_HOST)" "$msg"
  exit 2
fi

exists=$(jq -r --arg col "$COL" '.cluster.collections | has($col)' <<<"$CS_JSON")
if [ "$exists" != "true" ]; then
  msg="CRITICAL: collection '$COL' not found"
  echo "$CURRENT_TIME | $msg"
  logger -t "$LOG_TAG" -p ${LOG_FACILITY}.err "$msg"
  send_alert_mail "[ALERT] Solr collection not found ($COL)" "$msg"
  exit 2
fi

# Dedup node_name -> one active core per node
PAIR_TSV="$(jq -r --arg col "$COL" '
  .cluster.collections[$col].shards
  | to_entries[] | .value.replicas
  | to_entries[] | select(.value.state=="active")
  | [ .value.node_name, .value.core ] | @tsv
' <<<"$CS_JSON" | awk -F'\t' '!seen[$1]++')"

if [ -z "$PAIR_TSV" ]; then
  msg="CRITICAL: no active replicas for '$COL'"
  echo "$CURRENT_TIME | $msg"
  logger -t "$LOG_TAG" -p ${LOG_FACILITY}.err "$msg"
  send_alert_mail "[ALERT] No active replicas ($COL)" "$msg"
  exit 2
fi

ENC_Q=$(jq -rn --arg v "$SOLR_QUERY" '$v|@uri')
[ "$QUIET" = "false" ] && echo "$CURRENT_TIME | Simple node check (collection=$COL, q='${SOLR_QUERY}', timeAllowed=${SOLR_TIME_ALLOWED_MS}ms, quiet=$QUIET)"

ANY_FAIL=false
OK_COUNT=0
FAIL_COUNT=0
FAIL_LIST=()

while IFS=$'\t' read -r NODE_NAME CORE_NAME; do
  [ -z "$NODE_NAME" ] && continue
  HOSTPORT="${NODE_NAME%_solr}"
  URL="${SOLR_PROTO}://${HOSTPORT}/solr/${CORE_NAME}/select?wt=json&q=${ENC_Q}&rows=0&distrib=false&timeAllowed=${SOLR_TIME_ALLOWED_MS}"

  BODY="$(mktemp)"
  HTTP_CODE=$(curl "${CURL_OPTS[@]}" -o "$BODY" -w "%{http_code}" "$URL" || echo "000")

  if [ "$HTTP_CODE" != "200" ] || ! jq . >/dev/null 2>&1 <"$BODY"; then
    msg="NODE=$NODE_NAME CORE=$CORE_NAME | HTTP=$HTTP_CODE (select local failed)"
    [ "$QUIET" = "false" ] && echo "$CURRENT_TIME | CRITICAL: $msg"
    logger -t "$LOG_TAG" -p ${LOG_FACILITY}.err "CRITICAL: $msg"
    send_alert_mail "[ALERT] Solr node SELECT failure ($HOSTPORT)" "$msg"$'\n'"URL: $URL"
    ANY_FAIL=true; FAIL_COUNT=$((FAIL_COUNT+1)); FAIL_LIST+=("$NODE_NAME")
    rm -f "$BODY"; continue
  fi

  STATUS=$(jq -r '.responseHeader.status // 9' <"$BODY")
  QTIME=$(jq -r '.responseHeader.QTime // 0' <"$BODY")
  if [ "$STATUS" = "0" ]; then
    OK_COUNT=$((OK_COUNT+1))
    [ "$QUIET" = "false" ] && echo "$CURRENT_TIME | OK: NODE=$NODE_NAME CORE=$CORE_NAME | HTTP=200 status=0 QTime=${QTIME}ms"
  else
    msg="NODE=$NODE_NAME CORE=$CORE_NAME | HTTP=200 status=$STATUS (non-zero)"
    [ "$QUIET" = "false" ] && echo "$CURRENT_TIME | CRITICAL: $msg"
    logger -t "$LOG_TAG" -p ${LOG_FACILITY}.err "CRITICAL: $msg"
    send_alert_mail "[ALERT] Solr node SELECT non-zero ($HOSTPORT)" "$msg"$'\n'"URL: $URL"
    ANY_FAIL=true; FAIL_COUNT=$((FAIL_COUNT+1)); FAIL_LIST+=("$NODE_NAME")
  fi
  rm -f "$BODY"
done <<<"$PAIR_TSV"

# Summary (always print one line)
TOTAL=$((OK_COUNT + FAIL_COUNT))
if $ANY_FAIL; then
  echo "$CURRENT_TIME | RESULT=CRITICAL | OK=$OK_COUNT FAIL=$FAIL_COUNT TOTAL=$TOTAL | FAIL_NODES=$(printf '%s,' "${FAIL_LIST[@]}" | sed 's/,$//')"
  exit 2
else
  echo "$CURRENT_TIME | RESULT=OK | OK=$OK_COUNT FAIL=0 TOTAL=$TOTAL"
  exit 0
fi
