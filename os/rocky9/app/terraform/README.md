# 1. Terraform

## 1. CentOS 9에서 KVM 설치

### 1.1 Individual Package Installation for KVM

~~~~
dnf install -y qemu-kvm virt-install libvirt libvirt-client virt-manager libguestfs-tools python3-libvirt
~~~~

### 1.2 Start and Enable libvirtd Service

```
systemctl enable --now libvirtd
systemctl start libvirtd
```
<hr/>

### 1.3 Check if KVM is properly installed

```
virsh nodeinfo
```

### 1.3.1 Check KVM Module

```
lsmod | grep kvm
```

### 1.4 Set User Permissions

```
usermod -aG libvirt $(whoami)
newgrp libvirt
```

<hr/>

## 2. Configure Virtual Network

### 2.1 Check Virtual Machine

```
virsh list --all
```

```
virsh net-list --all
```

### 2.2 If the default network is disabled:

```
virsh net-start default
virsh net-autostart default
```
<hr/>

## 3. Create Virtual Machine

### 3.1 Create Virtual Machine w\ CentOS 9

```
virt-install \
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

<hr/>

## 4. Integrate Terraform with KVM

### 4.1 Install Terraform

```
dnf install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
dnf install terraform -y

terraform -v
```

### 2.2 Install Libvirt Terraform Provider

Download the latest release for the Terraform Provider
```
wget https://github.com/dmacvicar/terraform-provider-libvirt/archive/refs/tags/v0.7.6.tar.gz
```

```
tar -xzf v0.7.6.tar.gz

cd terraform-provider-libvirt-0.7.6
```

Build GoLang
```
dnf install -y golang
make build
```

`main.tf` create file
```
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "centos9_qcow2" {
  name   = "centos9.qcow2"
  pool   = "default"
  source = "ttps://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-20231002.0.x86_64.qcow2"
  format = "qcow2"
}

resource "libvirt_domain" "centos9_vm" {
  name   = "centos9-vm"
  memory = "2048"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  disk {
    volume_id = libvirt_volume.centos9_qcow2.id
  }

  network_interface {
    network_name = "default"
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "spice"
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

### 4.3 Run Terraform

Initialize Terraform:
```
TF_LOG=DEBUG terraform init
```

Review Terraform Plan:
```
terraform plan
```

Apply Terraform:
```
terraform apply
```

<hr/>

## 5. Manage Virtual Machines

Check Virtual Machine List:
```

```

Stop Virtual Machine:
```

```

Start Virtual Machine:
```

```


### 9.9

```

```

<hr/>

```

```

<hr/>

```

```

<hr/>

### References

- https://github.com/dmacvicar/terraform-provider-libvirt/releases/tag/v0.7.6

