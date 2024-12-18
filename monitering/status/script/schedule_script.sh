#!/bin/bash

# 실행 무한 루프
while true; do
  echo "Executing Solr Satus Check at $(date)"
  
  ./check_solr_status.sh http://10.100.61.69:8983 solr-weblog

  echo "=================="

  sleep 120       # 2분 대기 (120초)
done
