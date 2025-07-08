## [설치](install.md)
- ansible 스크립트을 통해 kafka 설치 및 클러스터링
- kafka 실행 명령어

## 클러스터링
1) [재배치 및 리더 재선출](./ansible_install/conf/reassign.yml)
- 노드가 추가될때 클러스터링은 replicas에는 포함되지 않음.
- replicas 포함 및 리더 재선출을 통해 사용가능한 노드로 반영.
2)
