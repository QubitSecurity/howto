#!/bin/bash

CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
FAILED_SERVERS=()

servers=(
  10.100.22.1 10.100.22.2 10.100.22.3 10.100.22.4 10.100.22.5
)

EXPECTED_VERSION="cdab6acb5312f1f57fed1ba78bcb815586abc0e7"

for server in "${servers[@]}"; do
  URL="http://$server:8833/filter/qubitsecversion"
  response=$(curl -s --max-time 5 "$URL")

  if [ $? -ne 0 ] || [ -z "$response" ]; then
    FAILED_SERVERS+=("$server(접속불가)")
    continue
  fi

  # JSON 여부 검사
  echo "$response" | jq . >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    FAILED_SERVERS+=("$server(응답오류)")
    continue
  fi

  returnCode=$(echo "$response" | jq -r '.returnCode // empty')
  serviceVersion=$(echo "$response" | jq -r '.version.serviceVersion // empty')
  coreVersion=$(echo "$response" | jq -r '.version.coreVersion // empty')

  if [[ "$returnCode" != "0" || -z "$serviceVersion" || -z "$coreVersion" ]]; then
    FAILED_SERVERS+=("$server(응답오류)")
  elif [[ "$serviceVersion" != "$EXPECTED_VERSION" ]]; then
    FAILED_SERVERS+=("$server(버전불일치)")
  fi
done

# 출력 (stdout → cron 리디렉션)
if [ ${#FAILED_SERVERS[@]} -eq 0 ]; then
  echo "$CURRENT_TIME | OK"
else
  echo "$CURRENT_TIME | FAIL: ${FAILED_SERVERS[*]}"

  {
    echo "[ALERT] 필터 서버 장애 감지"
    echo "실행 시간: $CURRENT_TIME"
    echo ""
    echo "장애 서버:"
    for s in "${FAILED_SERVERS[@]}"; do
      echo "- $s"
    done
  } | mail -s "[ALERT] 필터 서버 장애 감지" plura@qubitsec.com
fi
