CentOS 9에서 KVM을 기반으로 가상 서버를 구축하는 방식으로 안내드리겠습니다. 이 과정에서는 KVM(QEMU)을 사용하여 가상화 환경을 구성하고, Terraform을 활용해 가상 서버를 자동화하여 구축하는 절차를 설명합니다.

### KVM이란?
KVM(Kernel-based Virtual Machine)은 리눅스 커널을 기반으로 하는 가상화 솔루션입니다. 이를 통해 여러 개의 가상 서버를 실행할 수 있으며, Terraform을 활용하여 인프라를 코드로 관리할 수 있습니다.

### 1. CentOS 9에서 KVM 설치

#### 1.1. 필수 패키지 설치
CentOS 9에 KVM을 설치하기 위해 필요한 패키지를 설치합니다.

```bash
sudo dnf install @virt virt-install libvirt libvirt-python virt-manager libguestfs-tools -y
```

#### 1.2. Libvirtd 서비스 시작 및 활성화
Libvirt는 가상화를 관리하는 데 사용하는 백엔드입니다.

```bash
sudo systemctl enable --now libvirtd
sudo systemctl start libvirtd
```

#### 1.3. KVM이 제대로 설치되었는지 확인
KVM이 설치되고, 하드웨어 가상화가 활성화되었는지 확인합니다.

```bash
sudo virsh nodeinfo
```

출력 결과에서 `CPU model`에 `kvm` 관련 내용이 나와야 합니다. 또한, `sudo lsmod | grep kvm` 명령어로 KVM 모듈이 로드되어 있는지 확인할 수 있습니다.

#### 1.4. 사용자 권한 설정
현재 사용자가 가상화 그룹에 속해 있어야 KVM에 접근할 수 있습니다.

```bash
sudo usermod -aG libvirt $(whoami)
newgrp libvirt
```

### 2. 가상 네트워크 구성

KVM을 사용해 가상 서버를 만들기 전에, 가상 서버들이 통신할 수 있도록 네트워크 설정을 구성합니다.

```bash
sudo virsh net-list --all
```

`default` 네트워크가 비활성화된 경우:

```bash
sudo virsh net-start default
sudo virsh net-autostart default
```

### 3. 가상 머신 생성

가상 머신을 생성하려면 `virt-install` 명령을 사용합니다. 예를 들어, CentOS 9 기반의 가상 머신을 설치하려면 다음과 같이 실행합니다.

```bash
sudo virt-install \
    --name centos9-vm \
    --ram 2048 \
    --vcpus 2 \
    --disk path=/var/lib/libvirt/images/centos9-vm.qcow2,size=20 \
    --os-variant centos9 \
    --network network=default \
    --graphics none \
    --location 'http://mirror.centos.org/centos/9-stream/BaseOS/x86_64/os/' \
    --extra-args='console=ttyS0,115200n8 serial'
```

위 명령어는 다음을 수행합니다:
- `--name`: 가상 머신 이름.
- `--ram`: 가상 머신에 할당된 메모리.
- `--vcpus`: 가상 CPU 개수.
- `--disk`: 가상 디스크 경로 및 크기.
- `--os-variant`: 설치할 OS의 버전.
- `--network`: 네트워크 설정.
- `--graphics none`: GUI 없이 텍스트 모드로 설치.
- `--location`: OS 설치 경로 (CentOS 9 이미지).
- `--extra-args`: 텍스트 모드에서 설치를 위한 추가 인자.

설치가 끝나면 `virsh list` 명령어로 가상 머신 상태를 확인할 수 있습니다.

### 4. Terraform과 KVM 연동

KVM 환경에서 가상 머신을 Terraform으로 관리하려면 `terraform-provider-libvirt`를 사용합니다. 

#### 4.1. Terraform 설치

Terraform을 다운로드하고 설치합니다.

```bash
sudo dnf install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo dnf install terraform -y
```

#### 4.2. Libvirt Terraform Provider 설치

Terraform에서 libvirt를 사용할 수 있도록 provider를 설치합니다. 먼저 Terraform 구성 파일을 만듭니다.

```bash
mkdir ~/terraform-kvm
cd ~/terraform-kvm
```

`main.tf` 파일을 생성합니다.

```hcl
provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "centos9_qcow2" {
  name = "centos9.qcow2"
  pool = "default"
  source = "https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-20230425.1.x86_64.qcow2"
  format = "qcow2"
}

resource "libvirt_domain" "centos9_vm" {
  name   = "centos9-vm"
  memory = "2048"
  vcpu   = 2

  cloudinit = "${libvirt_cloudinit_disk.commoninit.id}"

  disk {
    volume_id = "${libvirt_volume.centos9_qcow2.id}"
  }

  network_interface {
    network_name = "default"
  }

  console {
    type = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type = "spice"
    listen_type = "none"
  }
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name = "centos9-cloudinit.iso"
  user_data = <<EOF
#cloud-config
password: centos
chpasswd: { expire: False }
ssh_pwauth: True
EOF
}
```

위 구성은 KVM 환경에서 CentOS 9 이미지를 다운로드하고, 가상 머신을 생성합니다. SSH 연결을 위해 기본 설정된 cloud-init 구성을 포함하고 있습니다.

#### 4.3. Terraform 실행

Terraform을 초기화하고 실행합니다.

1. Terraform 초기화:

   ```bash
   terraform init
   ```

2. Terraform 플랜 검토:

   ```bash
   terraform plan
   ```

3. Terraform 적용:

   ```bash
   terraform apply
   ```

가상 머신이 자동으로 생성되고 실행됩니다.

### 5. 가상 머신 관리

생성된 가상 머신을 관리하려면 다음 명령어들을 사용할 수 있습니다:

- 가상 머신 목록 확인:

  ```bash
  sudo virsh list --all
  ```

- 가상 머신 중지:

  ```bash
  sudo virsh shutdown centos9-vm
  ```

- 가상 머신 시작:

  ```bash
  sudo virsh start centos9-vm
  ```

### 결론

위 단계를 통해 CentOS 9에 KVM을 설치하고, Terraform과 연동하여 가상 서버를 자동으로 구축하는 방법을 배웠습니다. KVM을 활용하면 로컬에서 여러 가상 환경을 구축할 수 있고, Terraform을 이용하면 이를 코드로 관리할 수 있어 더 효율적으로 인프라를 운영할 수 있습니다.
