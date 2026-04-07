### 기존 k8s 클러스터링에 master 노드 추가



#### 기존 클러스터링 마스터 노드에서 클러스터링 토큰 확인
```
kubeadm token create --print-join-command

result ex:
kubeadm join xxx.xxx.xxx.xxx:xxxx --token bf23y9.xgnxxxxxxxxilttl9ks --discovery-token-ca-cert-hash sha256:643ff27e3xxxxxxxxxxxxxxxxxxxxxxxxxxx59d2e39f7f35c2d4bd
```

#### 기존 클러스터링 마스터 노드에서 클러스터링 키 확인
```
kubeadm init phase upload-certs --upload-certs

result ex:
[upload-certs] Using certificate key:
dc359fbc75xxxxxxxxxxxxxxxxxxxxxxx3722cc68af0fb4e74
```

#### 추가될 master 노드에서 실행
```
kubeadm join xxx.xxx.xxx.xxx:xxxx --token bf23y9.xgnxxxxxxxxilttl9ks --discovery-token-ca-cert-hash sha256:643ff27e3xxxxxxxxxxxxxxxxxxxxxxxxxxx59d2e39f7f35c2d4bd \
--certificate-key dc359fbc75xxxxxxxxxxxxxxxxxxxxxxx3722cc68af0fb4e74
```

#### 마스터 노드에서 확인
```
kubectl get node -o wide
```
