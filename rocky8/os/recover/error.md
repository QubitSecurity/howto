해당 화면은 CentOS 7에서 **XFS 파일 시스템이 손상되어 부팅 중 emergency mode로 진입한 상태**입니다. 이는 정전이나 갑작스러운 전원 차단으로 인해 파일 시스템의 메타데이터가 손상되었기 때문에 발생할 수 있습니다.

### 🔧 해결 방법 (복구 순서)

#### 1. `xfs_repair` 사용 준비
emergency shell에서는 루트 파일 시스템이 마운트되어 있을 수 있어서 직접 수리가 안 됩니다. **파일 시스템을 언마운트하고 `xfs_repair`를 실행**해야 합니다.

---

#### 2. 복구 절차 (LiveCD 또는 Rescue Mode 사용 추천)

1. **서버를 CentOS 7 설치 ISO로 부팅**하세요.
   - 설치 화면에서 `Troubleshooting` → `Rescue a CentOS system`을 선택하세요.

2. **쉘로 진입**
   - rescue 모드에서 루트 파일 시스템을 마운트하지 말고 **`Skip to shell`**을 선택합니다.

3. **디스크 확인 (예: `/dev/sdaX` 확인)**:
   ```bash
   lsblk
   ```

4. **문제 있는 파티션을 언마운트**:
   ```bash
   umount /dev/sdaX
   ```

5. **xfs_repair 실행**:
   ```bash
   xfs_repair /dev/sdaX
   ```

   > ※ `/dev/sdaX`는 실제 루트 파일 시스템이 설치된 파티션으로 바꾸세요. (예: `/dev/sda2`, `/dev/mapper/centos-root` 등)

6. **문제가 없으면 재부팅**:
   ```bash
   reboot
   ```

---

#### 3. 상황에 따라 아래 메시지가 나온다면?
```
xfs_repair: /dev/sdaX is mounted
xfs_repair: /dev/sdaX contains a mounted filesystem
```

- 이는 해당 파일 시스템이 **마운트되어 있기 때문에 수리할 수 없다는 뜻**입니다.
- **LiveCD**나 **rescue mode**에서 반드시 **언마운트 상태**로 수리해야 합니다.

---

### 📂 긴급 파일 백업이 필요하다면?
복구 전에 중요한 데이터가 있다면 아래 방법으로 백업도 가능합니다.

```bash
mkdir /mnt/usb
mount /dev/sdb1 /mnt/usb  # USB가 /dev/sdb1에 연결되었다고 가정
cp /run/initramfs/rdsosreport.txt /mnt/usb/
```

---

### ✅ 요약
- LiveCD 또는 Rescue Mode로 부팅
- 파일 시스템 언마운트
- `xfs_repair /dev/sdX` 실행
- 완료되면 재부팅

---

필요하시면 `lsblk`, `fdisk -l`, `mount` 결과를 공유해주시면 어떤 파티션을 수리해야 할지 더 정확히 도와드릴 수 있어요.
