### 기존 k8s 클러스터링에 worker 노드 추가



#### 기존 클러스터링 마스터 노드에서 클러스터링 값 추출
```
setenforce Permissive
```

#### SELinux 상태 확인
```
kubeadm token create --print-join-command

result ex:
kubeadm join xxx.xxx.xxx.xxx:xxxx --token bf23y9.xgnxxxxxxxxilttl9ks --discovery-token-ca-cert-hash sha256:643ff27e3xxxxxxxxxxxxxxxxxxxxxxxxxxx59d2e39f7f35c2d4bd
```

#### 추가될 worker 노드에서 실행
```
kubeadm join xxx.xxx.xxx.xxx:xxxx --token bf23y9.xgnxxxxxxxxilttl9ks --discovery-token-ca-cert-hash sha256:643ff27e3xxxxxxxxxxxxxxxxxxxxxxxxxxx59d2e39f7f35c2d4bd
```


#### 마스터 노드에서 확인
```
kubectl get node -o wide
```
