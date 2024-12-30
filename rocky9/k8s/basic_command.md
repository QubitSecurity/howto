###  노드 명령어
```
kubectl get nodes
kubectl get nodes -A
kubectl get nodes -o wide

systemctl restart kubelet 
```

### 파드 명령어
```
kubectl get pods
kubectl get pods (-A or -n [namespace] )
kubectl get pods -o wide
kubectl describe pods [pod_name] -n [namespace]
kubectl logs [pod_name] -n [namespace]
kubectl get pods -n [namespace -l k8s-app=[Labels]

kubectl delete pods [pod_name] -n [namespace]

```


### 서비스 명령어
```
kubectl get svc
kubectl get svc (-A or -n [namespace] )
kubectl get svc -o wide
kubectl describe svc [pod_name] -n [namespace]

kubectl delete svc [svc_name]

```

### 네임스페이스 명령어
```
kubectl get ns
kubectl describe ns [namespace]
kubectl create ns [namespace]
kubectl delete ns [namespace]
```

### 전체 확인, 삭제 명령어
```
kubectl get all  -n [namespace]
kubectl delete all  -n [namespace]
```

### 클러스터 명령ㅓㅇ
```
kubectl config view --raw
kubeadm reset
kubeadm init phase upload-certs --upload-certs

kubeadm token list
kubeadm token create --print-join-command

```
