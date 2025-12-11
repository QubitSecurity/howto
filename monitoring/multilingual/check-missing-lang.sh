#!/bin/bash
# check-lang-missing.sh
# /home/sysadmin/tmp 이하 JSON 파일에서
# JSON 내의 모든 객체를 돌면서 ko/en/ja 누락 여부 점검

TARGET_DIR="/root/event"

# jq 필요
if ! command -v jq >/dev/null 2>&1; then
    echo "jq 명령어를 찾을 수 없습니다. 먼저 설치해 주세요."
    exit 1
fi

# *.json 이 없을 때 for가 그대로 문자열을 넘기지 않도록
shopt -s nullglob

file_count=0
missing_count=0

for file in "$TARGET_DIR"/*.json; do
    ((file_count++))

    # 파일 안에서, ko/en/ja 키를 하나라도 가진 객체들 중
    # ko/en/ja 중 하나라도 빠진 객체가 "한 개라도" 있으면 true
    if jq -e '
        [ .. | objects
            | select(has("ko") or has("en") or has("ja"))
            | select((has("ko")|not) or (has("en")|not) or (has("ja")|not))
        ] | length > 0
    ' "$file" >/dev/null 2>&1; then
        echo "$(basename "$file")"
        ((missing_count++))
    fi
done

echo "------------------------------"
echo "Checked files : $file_count"
echo "Missing files : $missing_count"

if (( missing_count == 0 )); then
    echo "모든 JSON에서 ko/en/ja가 필요한 곳에는 모두 존재합니다. (누락 없음)"
fi
