## [설치](./ansible_install/readme.md)
- ansible 스크립트를 통한 kafka 설치 및 클러스터링.
- ansible 스크립트를 통한 cmak, akhq 설치.

## [시작](start.md)
- kafka 및 cmak, akhq 실행 명령어.

## 클러스터링
1) [zookeeper 모드 vs kraft 모드](zk_vs_kraft.md)
- kafka 클러스터링 모드 비교
2) [재배치 및 리더 재선출](./ansible_install/conf/reassign.yml)
- 노드가 추가될때 클러스터링은 replicas에는 포함되지 않음.
- replicas 포함 및 리더 재선출을 통해 사용가능한 노드로 반영.
- ansbile 스크립트를 통해 replicas 포함 및 리더 재선출.

