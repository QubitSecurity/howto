
# inversion check
 curl "http://10.100.61.84:8983/solr/weblog_shard91_replica_n858/replication?command=details"
 curl "http://10.100.61.85:8983/solr/weblog_shard91_replica_n888/replication?command=details"


 # 리플리카 추가 삭제

 [sysadmin@020250-ansible ~]$ curl "http://10.100.61.84:8983/solr/admin/collections?action=ADDREPLICA&collection=weblog&shard=shard91&node=10.100.61.85:8983_solr"
{
  "responseHeader":{
    "status":0,
    "QTime":334},
  "success":{
    "10.100.61.85:8983_solr":{
      "responseHeader":{
        "status":0,
        "QTime":215},
      "core":"weblog_shard91_replica_n892"}}}
[sysadmin@020250-ansible ~]$ curl -s "http://10.100.61.84:8983/solr/admin/collections?action=CLUSTERSTATUS&collection=weblog" | jq '.cluster.collections.weblog.shards.shard91'
{
  "range": null,
  "state": "active",
  "replicas": {
    "core_node859": {
      "core": "weblog_shard91_replica_n858",
      "node_name": "10.100.61.84:8983_solr",
      "base_url": "http://10.100.61.84:8983/solr",
      "state": "active",
      "type": "NRT",
      "force_set_state": "false",
      "leader": "true"
    },
    "core_node893": {
      "core": "weblog_shard91_replica_n892",
      "node_name": "10.100.61.85:8983_solr",
      "base_url": "http://10.100.61.85:8983/solr",
      "state": "recovering",
      "type": "NRT",
      "force_set_state": "false"
    }
  },
  "health": "ORANGE"
}

# 복제 상태 확인

 curl -s "http://10.100.61.84:8983/solr/admin/collections?action=CLUSTERSTATUS&collection=weblog" | jq '.cluster.collections.weblog.shards.shard91.replicas'

# 병합 상태 확인

curl -s "http://10.100.61.149:8983/solr/admin/cores?action=STATUS"

curl -s "http://127.0.0.1:8983/solr/admin/cores?action=STATUS"

 
# 로그 확인하기

tail -f ./solr/server/logs/solr.log | grep -E "error|warn|merge|commit"


### CLI 명령어 (삭제된 오래된 버전의 명령어)
./solr/bin/solr optimize -c weblog_shard1_replica_n722 -s 100


---

curl "http://10.100.61.149:8983/solr/admin/collections?action=ADDREPLICA&collection=weblog&shard=shard1&node=10.100.61.148:8983_solr"

 curl -s "http://10.100.61.149:8983/solr/admin/collections?action=CLUSTERSTATUS&collection=weblog" | jq '.cluster.collections.weblog.shards.shard1.replicas'
 
