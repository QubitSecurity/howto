


[ansible ~]$ curl -s "http://10.100.61.149:8983/solr/admin/cores?action=STATUS" | jq '.status | keys'
[
  "weblog_shard1_replica_n722"
]


# 서버 노드 상태 확인
curl -s "http://10.100.61.149:8983/solr/admin/cores?action=STATUS&wt=json"


# 컬렉션이 정상인지 조회합니다.

curl "http://10.100.61.149:8983/solr/admin/collections?action=CLUSTERSTATUS&collection=weblog&wt=json"

# Green 상태 출력
curl -s "http://10.100.61.149:8983/solr/admin/collections?action=CLUSTERSTATUS&collection=weblog&wt=json" | jq '.cluster.collections.weblog.shards | to_entries[] | {shard: .key, health: .value.health, replicas: (.value.replicas | to_entries[] | {replica: .key, state: .value.state, core: .value.core, node_name: .value.node_name, leader: .value.leader})}'


# 컬렉션 중에서 문제가 되는 것이 있는지 조사합니다. 즉, Green이 아닌 것만 출력
curl -s "http://10.100.61.149:8983/solr/admin/collections?action=CLUSTERSTATUS&collection=weblog&wt=json" | jq '.cluster.collections.weblog.shards | to_entries[] | select(.value.health != "GREEN") | {shard: .key, health: .value.health}'

# Active 아닌 것 출력
curl -s "http://10.100.61.149:8983/solr/admin/collections?action=CLUSTERSTATUS&collection=weblog&wt=json" | jq '.cluster.collections.weblog.shards | to_entries[] | {shard: .key, replicas: (.value.replicas | to_entries[] | select(.value.state != "active") | {replica: .key, core: .value.core, node_name: .value.node_name, state: .value.state})}'

4. Cluster State 확인
Cluster 상태를 확인하려면 clusterstate.json을 추출할 수 있습니다:
curl -s "http://10.100.61.149:8983/solr/admin/zookeeper?detail=true" | jq '.tree | .[] | select(.name=="clusterstate.json") | .data'
