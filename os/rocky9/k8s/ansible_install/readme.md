### 0. 실행 환경
```
ansible hosts 파일 경로 : /home/qubit/ansible/hosts
실행 경로 : (/usr/lib/systemd/system/mysqld.service)

파일 종류
k8s-haproxy.yml - k8s 클러스터링 내부 haproxy 설치
k8s-master.yml - k8s 클러스터링 master node 설치
k8s-worker.yml - k8s 클러스터링 worker node 설치
```

### 1. 설치 방법
```
먼저  각 yml 파일 상단에 있는 변수를 맞게 지정

이후 아래 순서대로 yml 파일 실행
ansible-playbook -i /home/qubit/ansible/hosts /home/qubit/ansible/k8s/k8s-haproxy.yml
ansible-playbook -i /home/qubit/ansible/hosts /home/qubit/ansible/k8s/k8s-master.yml
ansible-playbook -i /home/qubit/ansible/hosts /home/qubit/ansible/k8s/k8s-worker.yml

```
