
## 참고 사항
```
쿠버네티스 기반으로 실행되는 프로메테우스는 재시작되면 기존 메트릭 데이터가 삭제.
지정된 Worker 노드에 PV를 설정하고, 이를 통해 메트릭 데이터 로컬 저장 유지.
```

## Prometheus
### 1. values.yaml 파일 추출
```
실행 중인 프로메테우스의 yaml 파일을 추출
helm get values prometheus -n monitoring -a > values.yaml
```

### 2. 스토리지 class 설정
```
vi local-storageclass.yaml

apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-prometheus
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer

적용
kubectl apply -f local-storageclass.yaml

확인
kubectl get storageclass
```

### 3. 지정 워커 노드 PV 설정
```
vi prometheus-pv.yaml

apiVersion: v1
kind: PersistentVolume
metadata:
  name: prometheus-pv-0
spec:
  capacity:
    storage: 15Gi	#용량을 15G 설정
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-prometheus
  local:
    path: /prometheus_data       # 실제 디스크 해당 워커 노드에 경로 생성
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - <실제-워커노드-이름>  # kubectl get nodes 를 통해 확인


적용
kubectl apply -f prometheus-pv.yaml

확인
kubectl get persistentvolume
```

### 4. values.yaml 파일 수정
```
vi values.yaml
불필요 부분 false 설정 (yaml 파일 내 'webhook' 검색하여 관련 이미지 실행 및 파드가 생성되지 않도록 false 설정)
    patch:
      affinity: {}
      annotations: {}
      enabled: false  #true > false 로 변경
      image:
        pullPolicy: IfNotPresent
        registry: registry.k8s.io
        repository: ingress-nginx/kube-webhook-certgen
        sha: ""
        tag: v1.6.3

프로메테우스 지정된 Worker 노드 PV 설정
prometheus:
  prometheusSpec:
    nodeSelector:
      kubernetes.io/hostname: <실제-워커노드-이름>  # 위 prometheus-pv.yaml 작성 시, 동일 Worker 노드 지정

    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: local-prometheus  #스토리지 class 설정
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 15Gi        #PV 용량 설정

yaml 재적용
helm upgrade prometheus prometheus-community/kube-prometheus-stack --namespace monitoring -f /PATH/values.yaml --debug

확인
kubectl get persistentvolumeclaim
```
