다음은 **Shards 추가 및 Replica 등록**을 절차적으로 처리하고, 문제가 발생했을 경우 자동화된 방식으로 점검, 취소, 재등록 과정을 진행하는 워크플로우입니다.

---

## **절차적 워크플로우**

### **1. Shard 추가**
새로운 Shard를 추가합니다.

#### 명령:
```bash
curl "http://<SOLR_LEADER>:8983/solr/admin/collections?action=CREATESHARD&collection=<COLLECTION_NAME>&shard=<SHARD_NAME>"
```

#### 예시:
```bash
curl "http://10.100.61.84:8983/solr/admin/collections?action=CREATESHARD&collection=weblog&shard=shard92"
```

---

### **2. Replica 등록**
Shard에 새 Replica를 등록합니다.

#### 명령:
```bash
curl "http://<SOLR_LEADER>:8983/solr/admin/collections?action=ADDREPLICA&collection=<COLLECTION_NAME>&shard=<SHARD_NAME>&node=<TARGET_NODE>"
```

#### 예시:
```bash
curl "http://10.100.61.84:8983/solr/admin/collections?action=ADDREPLICA&collection=weblog&shard=shard92&node=10.100.61.85:8983_solr"
```

---

### **3. 상태 확인**
Replica 상태를 확인하여 등록이 성공적으로 진행되었는지 점검합니다.

#### 명령:
```bash
curl -s "http://<SOLR_LEADER>:8983/solr/admin/collections?action=CLUSTERSTATUS&collection=<COLLECTION_NAME>" | jq '.cluster.collections.<COLLECTION_NAME>.shards.<SHARD_NAME>.replicas'
```

#### 예시:
```bash
curl -s "http://10.100.61.84:8983/solr/admin/collections?action=CLUSTERSTATUS&collection=weblog" | jq '.cluster.collections.weblog.shards.shard92.replicas'
```

#### 확인할 내용:
- `state`가 `active` 또는 `recovering`인지 확인.
- `state`가 `down`이거나 없을 경우 다음 절차 진행.

---

### **4. Replica 등록 취소**
상태가 `down`이거나 문제가 발생했을 경우, 잘못 등록된 Replica를 삭제합니다.

#### 명령:
```bash
curl "http://<SOLR_LEADER>:8983/solr/admin/collections?action=DELETEREPLICA&collection=<COLLECTION_NAME>&shard=<SHARD_NAME>&replica=<REPLICA_NAME>"
```

#### 예시:
```bash
curl "http://10.100.61.84:8983/solr/admin/collections?action=DELETEREPLICA&collection=weblog&shard=shard92&replica=core_nodeXXX"
```

---

### **5. Replica 재등록**
삭제 후, Replica를 다시 등록합니다.

#### 명령:
```bash
curl "http://<SOLR_LEADER>:8983/solr/admin/collections?action=ADDREPLICA&collection=<COLLECTION_NAME>&shard=<SHARD_NAME>&node=<TARGET_NODE>"
```

#### 예시:
```bash
curl "http://10.100.61.84:8983/solr/admin/collections?action=ADDREPLICA&collection=weblog&shard=shard92&node=10.100.61.85:8983_solr"
```

---

### **6. 상태 모니터링**
Replica 등록 후 지속적으로 상태를 모니터링합니다.

#### 명령:
```bash
curl -s "http://<SOLR_LEADER>:8983/solr/admin/collections?action=CLUSTERSTATUS&collection=<COLLECTION_NAME>" | jq '.cluster.collections.<COLLECTION_NAME>.shards.<SHARD_NAME>.replicas'
```

#### 상태 점검:
- `state`가 `active`로 전환되었는지 확인.
- 여전히 `recovering` 상태라면 추가 점검 필요.

---

### **7. Replica 복구 요청 (필요 시)**
Replica가 `recovering` 상태에서 복구가 멈춘 경우, 수동으로 복구를 요청합니다.

#### 명령:
```bash
curl "http://<TARGET_NODE>:8983/solr/admin/cores?action=REQUESTRECOVERY&core=<CORE_NAME>"
```

#### 예시:
```bash
curl "http://10.100.61.85:8983/solr/admin/cores?action=REQUESTRECOVERY&core=weblog_shard92_replica_nXXX"
```

---

### **8. ZooKeeper 상태 점검**
ZooKeeper의 `state.json` 파일을 확인하여 클러스터 상태와 동기화 여부를 점검합니다.

#### 명령:
```bash
curl -s "http://<SOLR_LEADER>:8983/solr/admin/zookeeper?detail=true&path=/collections/<COLLECTION_NAME>/state.json" | jq '.shards.<SHARD_NAME>'
```

---

## **워크플로우 요약**
1. **Shard 생성** → Replica 등록.
2. Replica 상태 확인 (`active`, `recovering`인지 확인).
3. 문제가 있으면 Replica 삭제 → 재등록.
4. 상태 모니터링 및 복구 요청.
5. ZooKeeper에서 상태 점검.

이 과정을 반복적으로 실행하며 상태를 점검하고 복구를 진행하세요. 필요한 경우 자동화를 위한 스크립트도 작성할 수 있습니다. 추가로 문제가 발생하거나 자동화 스크립트가 필요하다면 알려주세요!
