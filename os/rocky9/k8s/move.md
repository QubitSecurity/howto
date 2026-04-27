<!--
결론부터 말하면:

> ❗ **무조건 “Worker → Control Plane” 순서로, 한 대씩 drain 후 이동”** 해야 합니다.

---
-->
# ✅ 전체 전략 (핵심 요약)

```
1. Worker 노드부터 하나씩 drain → VM 종료 → 이동 → 기동 → 복귀
2. Worker 전부 완료 후
3. Control Plane (Master) 노드 순차 이동 (etcd quorum 유지 필수)
```

---

# 🚨 절대 하면 안 되는 것

```
❌ 여러 노드 동시에 종료
❌ Master 먼저 종료
❌ drain 없이 바로 VM 종료
```

→ 장애 바로 발생 (Pod 유실 / etcd quorum 깨짐)

---

# 🧩 1단계: Worker 노드 이동 (안전 구간)

## ✔️ 대상

```
구성된 Worker 노드들
ex.
021090 ~ 021099 (worker 10대)
```


---

## 🔁 Worker 1대씩 반복 절차

### ① Pod 안전하게 비우기 (핵심)

```bash
kubectl drain [Worker Node Hostname]  --ignore-daemonsets --delete-emptydir-data --force
```

✔ 의미:

* 일반 Pod → 다른 노드로 이동
* DaemonSet (calico, node-exporter 등) → 유지

---

### ② 상태 확인

```bash
kubectl get pod -A -o wide | grep [Worker Node Hostname]
```

👉 남아있는 건 DaemonSet만 있어야 정상

---

### ③ VM 종료 및 이동

```bash
shutdown -h now
```

→ KVM에서 VM 이동

---

### ④ VM 기동 후

```bash
(swap 설정 되어 있는 경우)
swapoff -a

crio, kubelet 재기동
systemctl start crio
systemctl start kubelet
```

확인:

```bash
kubectl get nodes
```

→ Ready 상태 확인

---

### ⑤ 스케줄링 복구

```bash
kubectl uncordon [Worker Node Hostname]
```

---

### 🔁 위 절차를 worker 전체 반복


<!--
---

# 🧠 Worker 이동 순서 (추천)

👉 Pod 분산 상태 기준:

```
021090 → 021092 → 021094 → 021096 → 021098
→ 021091 → 021093 → 021095 → 021097 → 021099
```

✔ 이유:

* 동일 workload 분산 유지
* 특정 서비스 몰림 방지

---
-->


# ⚠️ 중요 체크 (Worker 단계)

### Pod 분산 확인

```bash
kubectl get pod -A -o wide | grep [Service Namespace]
```

👉 특정 노드에 몰리지 않게 확인

---


<br><br>
# 🧩 2단계: Control Plane 이동 (위험 구간)

## ✔️ 대상

```
구성된 Master 노드
ex.
021085, 021086, 021087 (Master 3대)
```


👉 여기는 etcd quorum 때문에 매우 중요

---

## 🚨 etcd Quorum 조건

* 3대 중 최소 2대 살아있어야 정상

```
1대 down → OK
2대 down → 클러스터 멈춤
```

---

## 🔁 Master 이동 절차 (1대씩)

### ① 스케줄링 차단

```bash
kubectl cordon [Master Node Hostname] 
```

---

### ② (옵션) Pod drain

※ control-plane은 일반적으로 workload 없음

```bash
kubectl drain [Master Node Hostname] --ignore-daemonsets
```

---

### ③ etcd 상태 확인 (중요)

```bash
ETCDCTL_API=3 etcdctl endpoint health
```

👉 모든 노드 healthy 확인

---

### ④ VM 종료 및 이동

```bash
shutdown -h now
```

---

### ⑤ VM 기동 후 확인

```bash
(swap 설정 되어 있는 경우)
swapoff -a

crio, kubelet 재기동
systemctl start crio
systemctl start kubelet
```

```bash
kubectl get nodes
```

```bash
ETCDCTL_API=3 etcdctl endpoint health
```

---

### ⑥ 복구

```bash
kubectl uncordon [Master Node Hostname]
```

---
<!--
## 🔁 Master 순서 (추천)

```
021085 → 021086 → 021087
```

👉 순서는 크게 상관없지만 “1대씩”이 핵심

---
-->

# 🧪 전체 과정 중 체크 포인트

## ✔️ 노드 상태

```bash
kubectl get nodes
```

---

## ✔️ Pod 상태

```bash
kubectl get pod -A
```

---

## ✔️ 시스템 Pod 확인

```bash
kubectl get pod -n kube-system
```

👉 특히:

* coredns
* calico
* kube-apiserver
* etcd

---

# 🚨 장애 방지 핵심 3가지

### 1️⃣ 항상 1대씩만 작업

→ 병렬 작업 금지

---

### 2️⃣ drain 필수 (worker)

→ 안 하면 Pod 유실됨

---

### 3️⃣ etcd quorum 유지

→ master는 특히 천천히

---

# 🔥 한 줄 핵심

> **“Worker drain → 순차 이동 → Master 1대씩 이동 (etcd 유지)”**

---


