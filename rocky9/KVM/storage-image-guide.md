### KVM 디스크 이미지 형식 분석: RAW vs QCOW2


## 1. 디스크 형식(raw vs qcow2) 비교

### 1-1. 기술적 특성 비교

| 항목 | qcow2 | raw |
|------|-------|-----|
| 디스크 사용 방식 | 동적 할당 (thin provisioning) | 고정 크기 (preallocated) |
| I/O 성능 | 느림 (메타데이터, 압축, COW 처리) | 빠름 (바이트 블록 직접 접근) |
| 스냅샷 기능 | 내부 지원 (메타데이터 기반) | 없음 (외부 도구 필요) |
| 압축 / 암호화 | 지원 가능 | 불가능 |
| Zero Block 처리 | 0 블록은 디스크에 저장하지 않음 | 실제로 저장 |
| 디스크 정렬 | 정렬 문제 가능성 있음 | 단순하고 정렬 잘 됨 |
| 버스트 성능 | 약함 (중간 메타데이터 경유) | 강함 (디스크 직통) |
| 변환 가능성 | raw로 쉽게 변환 가능 | qcow2로 쉽게 변환 가능 |
| 공간 최적화 | 가능 (압축, discard 지원 등) | 불가 |
| 호스트 접근성 | 해석 불가 (도구 필요) | `dd`, `mount`, `losetup` 바로 가능 |
| 안정성 (쓰기 중단) | 메타데이터 손상 가능성 있음 | 구조 단순, 손상 위험 낮음 |

---

### 1-2. 형식 변환 명령어 예시

```bash
# raw → qcow2
qemu-img convert -f raw original.img -O qcow2 converted.qcow2

# qcow2 → raw
qemu-img convert -f qcow2 original.qcow2 -O raw converted.img
```

[RedHat 공식 문서 링크 ↗](https://docs.redhat.com/ko/documentation/red_hat_enterprise_linux/8/html/configuring_and_managing_virtualization/managing-virtual-disk-images-by-using-the-cli_managing-storage-for-virtual-machines#converting-between-virtual-disk-image-formats_managing-virtual-disk-images-by-using-the-cli)

---

## 2. RAW 디스크 생성 방법 (KVM 환경)

### 2-1. CLI로 생성하는 방법
- 생성 경로는 `/var/lib/libvirt/images/`이며, libvirt가 접근할 수 있어야 합니다.
  
```bash
qemu-img create -f raw /var/lib/libvirt/images/mydisk.img 20G
```

- VM 설치를 위한 ISO 이미지 준비 후, virt-install 명령으로 설치를 진행합니다.

```bash
virt-install --name myvm --ram 2048 --disk path=/var/lib/libvirt/images/mydisk.img,format=raw --vcpus 2 --os-type linux --cdrom /path/to/installer.iso --network bridge=virbr0
```

- 설치 중 콘솔 접속 형식은 다음과 같습니다:

```bash
virsh console myvm
```

---

### 2-2. GUI(virt-manager)로 생성하는 방법

[참고 블로그 링크 ↗](https://lilo.tistory.com/95)

1. `virt-manager` 실행 → 새 VM 만들기 클릭  
2. ISO 이미지 선택  
3. Step 4 of 5 화면에서 "Select or create custom storage" 체크  
4. Choose Storage → 우측 `Volumes → +` 선택  
5. 형식: `raw`, 용량 입력 후 생성  
6. Finish 클릭 → raw 디스크 생성 완료

---

## 3. 실전 적용: Solr 등 고IO 서비스에 적합한 디스크 선택

| 항목 | raw | qcow2 |
|------|-----|-------|
| Solr 검색/인덱싱 | 빠르고 안정적 | 느림, 레이턴시 발생 |
| 대량 로그/쓰기 | 고속 처리 가능 | write amplification 발생 |
| 디스크 용량 예측 | 예측 가능 (고정 크기) | 실제 사용량 추적 어려움 |
| 리커버리 안정성 | 안전 (충분 공간 확보 시) | 용량 초과 시 복구 실패 가능 |
| 디스크 풀 설계 | 설계 간편 | 비예측적 |
| 스냅샷 | 수동 처리 필요 | 자동 지원 |
| 마운트 분석 | 직접 처리 가능 (`losetup`, `dd`) | 파싱 도구 필요 |
| 장애 대응 | 단순 파일 복사로 가능 | 복잡하고 손상 위험 |

---

## 4. 결론

- 디스크 공간이 **제한적이고 테스트용**이라면 `qcow2` 형식, 
- 그러나 **성능이 중요하고 안정성이 핵심인 운영 환경**이라면 `raw` 선택이 유리함
