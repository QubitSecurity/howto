#!/bin/bash

# Solr Cluster 상태 정보 가져오기
CLUSTER_INFO=$(curl -s "http://10.100.61.228:8983/solr/admin/collections?action=CLUSTERSTATUS&collection=weblog&wt=json")

# 병합 작업 명령을 저장할 단일 파일
OUTPUT_FILE="./merge_commands.txt"

# 출력 파일 초기화
echo "Starting merge process for leaders at $(date)" > "$OUTPUT_FILE"
echo >> "$OUTPUT_FILE"

# Shard 단위 파일 생성 (1부터 89까지)
for i in $(seq 1 89); do
  shard="shard$i"
  echo "$shard" >> "$OUTPUT_FILE"

  # Shard에 포함된 코어들 가져오기
  CORES=$(echo "$CLUSTER_INFO" | jq -r ".cluster.collections.weblog.shards.${shard}.replicas // empty | to_entries[] | .value.base_url + \"/\" + .value.core + \" \" + (.value.isLeader // false | tostring)")

  if [[ -z "$CORES" ]]; then
    echo "No replicas found for $shard" >> "$OUTPUT_FILE"
    echo >> "$OUTPUT_FILE"
    continue
  fi

  # 리더 선택 또는 첫 번째 활성 코어 선택
  leader_found=false
  for core_info in $CORES; do
    core_url=$(echo "$core_info" | awk '{print $1}')
    is_leader=$(echo "$core_info" | awk '{print $2}')

    if [[ "$is_leader" == "true" ]]; then
      echo "curl \"$core_url/update?optimize=true&maxSegments=50\"" >> "$OUTPUT_FILE"
      leader_found=true
      break
    fi
  done

  # 리더가 없으면 첫 번째 코어 사용
  if [[ "$leader_found" == "false" ]]; then
    fallback_core=$(echo "$CORES" | head -n 1 | awk '{print $1}')
    echo "curl \"$fallback_core/update?optimize=true&maxSegments=50\" # fallback to first active core" >> "$OUTPUT_FILE"
  fi

  echo >> "$OUTPUT_FILE"
done

echo "Merge command generation completed at $(date)" >> "$OUTPUT_FILE"
