## 설치 전 참고 사항
```
쿠버네티스를 대상으로 모니터링하기 위한 설치
(노드 환경을 위한 설치 방법 X)
```
### 0. 사전 작업
```
helm 다운로드
wget https://get.helm.sh/helm-v3.16.3-linux-amd64.tar.gz


압축 해제
tar -zxvf helm-v3.16.3-linux-amd64.tar.gz

cp linux-amd64/helm /sbin/
```



## Prometheus+Grafana
```
helm 을 통해 설치하는 경우 stack을 제공하여 프로메테우스와 그라파나 함께 설치 가능.
```
### 1. 설치
```
프로메테우스 helm charts 레포지포리 등록
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

프로메테우스 레포지토리 업데이트(반영)
helm repo update

프로메테우스 namespace 정의
kubectl create ns monitoring

설치
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring
※ 설치하면 자동 실행

삭제
heml uninstall prometheus -n monitoring

```

### 2. 서비스 수정
```
최초 실행 시 Cluster IP로 설정되어 있기에 외부에서는 확인 불가
nodeport 설정을 통해 외부 접속 설정

그라파나 설정
kubectl edit service -n monitoring prometheus-grafana
### 노드포트 추가 및 타입수정
+++
  ports:
  - name: http-web
    nodePort: 31000
    port: 80
    protocol: TCP
    targetPort: 3000
  selector:
    app.kubernetes.io/instance: prometheus
    app.kubernetes.io/name: grafana
  sessionAffinity: None
  type: NodePort
+++

프로메테우스 설정
kubectl edit service -n monitoring prometheus-kube-prometheus-prometheus
+++
### 노드포트 추가 및 타입수정
  ports:
  - name: http-web
    nodePort: 30090
    port: 9090
    protocol: TCP
    targetPort: 9090
  - name: reloader-web
    nodePort: 31365
    port: 8080
    protocol: TCP
    targetPort: reloader-web
  selector:
    app.kubernetes.io/name: prometheus
    operator.prometheus.io/name: prometheus-kube-prometheus-prometheus
  sessionAffinity: None
  type: NodePort
+++

※ 저장&종료하면 서비스에 자동 반영.
```


### 3. 접속 방법
```
그라파나 웹 UI 접속
http://IP:31000
※svc 수정으로 작성된 포트

그라파나의 초기 비밀번호 확인
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode

프로메테우스 웹 UI 접속
http://IP:30010
※svc 수정으로 작성된 포트
```

### 4. 유의 사항
```
2개의 웹 UI 모두, 실행하는 웹브라우저의 시스템 시간에 따라 정상 확인되지 않을 수 있음.
반드시 접속 환경 시스템의 시간 설정 확인 필수
```
