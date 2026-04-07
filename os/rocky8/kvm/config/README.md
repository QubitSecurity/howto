## 1. Virtual Network Interface

### 1.1 use 'e1000' NIC device drivers instead of 'virtio' drivers in the guest setting

[![rtaImage](https://github.com/QubitSecurity/documentation/assets/24949168/f61fbc97-56c4-4d7a-96ae-1e345c115407)](https://user-images.githubusercontent.com/24949168/272147595-14af4c4a-44fb-45d8-95ba-9cfd41887837.jpeg)


### 1.2 Keep specific vnet(xx) adapter on host system for VM the same after VM shutdown/reboot

    vi /etc/libvirt/qemu/010013-centos7d-temp.xml
    
    <interface type='bridge'>
    ...
    <source network='default'/>
    <target dev='vnet1'/>
    ...
    </interface>

    systemctl restart libvirtd

    
## X. Useful Links

    - https://forums.ivanti.com/s/article/KB40607
    - https://serverfault.com/questions/1109941/keep-specific-vnetxx-adapter-on-host-system-for-vm-the-same-after-vm-shutdown
