## 1. dhcp 서버 설치
### 1.1 dhcp 설치
```
dnf -y install dhcp-server
```
### 1.2 dhcpd.conf 설정
```
vi /etc/dhcp/dhcpd.conf

#
# DHCP Server Configuration file.
#   see /usr/share/doc/dhcp-server/dhcpd.conf.example
#   see dhcpd.conf(5) man page
#

option space pxelinux;
option pxelinux.magic code 208 = string;
option pxelinux.configfile code 209 = text;
option pxelinux.pathprefix code 210 = text;
option pxelinux.reboottime code 211 = unsigned integer 32;
option architecture-type code 93 = unsigned integer 16;

# ※예시 dhcp 범위 설정
# 대역 10.11.11.0/24
# 할당 범위 10.11.11.230~234
subnet 10.11.11.0 netmask 255.255.255.0 {
        #option routers 192.168.122.1;
        range 10.11.11.230 10.11.11.234;
        #filename "pxelinux.0";
        next-server 10.11.11.242; #tftp 서버(동일)

        if option architecture-type = 00:07 {
                filename "EFI/BOOT/BOOTX64.EFI";
        } else {
                filename "pxelinux.0";
        }
}
```
### 1.3 firewalld 정책 수정 및 dhcpd 시작
```
firewall-cmd --add-service=dhcp --permanent
firewall-cmd --reload

systemctl enable --now dhcpd
systemctl restart dhcpd
systemctl status  dhcpd
```
<br><br>

## 2. tftp, syslinux 설치
### 2.1 tftp, syslinux 설치
```
dnf -y install tftp-server syslinux
systemctl enable --now tftp.socket
```

### 2.2 관련 파일 재배치
```
cp /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot/
cp /usr/share/syslinux/{menu.c32,vesamenu.c32,ldlinux.c32,libcom32.c32,libutil.c32} /var/lib/tftpboot/
```

### 2.3 firewalld 정책 수정
```
firewall-cmd --add-service=tftp --permanent
firewall-cmd --reload
```
<br><br>
## 3. httpd 설치
### 3.1 httpd 설치
```
dnf -y install httpd
```

### 3.2 httpd 설정 변경
```
vi /etc/httpd/conf/httpd.conf (리스닝 포트 변경 - 포트 충돌 배제)

#Listen 80
Listen 8080
```

### 3.3 firewalld 정책 수정 및 httpd 시작
```
firewall-cmd --add-port=8080/tcp --permanent
firewall-cmd --reload
mv /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.conf_bak
systemctl restart httpd
```
<br><br>

## 4. OS ISO 파일 마운트
### 4.1 ISO 파일 마운트 및 httpd 배치(ISO 파일 저장되어 있다고 가정)
```
mkdir /root/pxe_iso_files
mkdir /var/www/html/pxe
mkdir /var/www/html/pxe/rockylinux9
mount -t iso9660 -o loop,ro /root/pxe_iso_files/Rocky-9.6-x86_64-dvd.iso /var/www/html/pxe/rockylinux9
systemctl restart httpd
```
### 4.2 iso 영구 마운트
```
vi /etc/fstab

/root/pxe_iso_files/Rocky-9.6-x86_64-dvd.iso /var/www/html/pxe/rockylinux9 iso9660 loop,ro 0 0
```
<br><br>
## 5. tftp 부팅 메뉴 설정
### 5.1 tftp 디렉토리 생성 및 부팅 파일 배치
```
cp /var/www/html/pxe/rockylinux8/images/pxeboot/{vmlinuz,initrd.img} /var/lib/tftpboot/rockylinux8
```
### 5.2 부팅 메뉴 작성
```
vi /var/lib/tftpboot/pxelinux.cfg/default

default menu.c32
#default vesamenu.c32
prompt 0
timeout 600
ONTIMEOUT 1

menu title ######## PXE Boot Menu ########
 label 1
 menu label ^1) Install Rocky Linux 9
 menu default
 kernel rockylinux9/vmlinuz
 append initrd=rockylinux9/initrd.img ip=dhcp inst.repo=http://[PXE SERVER IP]:8080/pxe/rockylinux9 inst.ks=http://[PXE SERVER IP]:8080/pxe/ks.cfg
```

## 6. UEFI 모드 추가
### 6.1 관련 패키지 설치 및 복사
```
dnf install -y grub2-efi-x64 shim-x64

cp /boot/efi/EFI/rocky/grubx64.efi /var/lib/tftpboot/EFI/BOOT/grubx64.efi
cp /boot/efi/EFI/rocky/grubx64.efi /var/lib/tftpboot/EFI/BOOT/BOOTX64.EFI
```
### 6.2 grub.cfg 파일 생성
```
vi /var/lib/tftpboot/EFI/BOOT/grub.cfg

set timeout=10
set default=0

menuentry "Install Rocky Linux 9 (UEFI)" {
    linuxefi /rockylinux9/vmlinuz ip=dhcp inst.repo=http://[PXE SERVER IP]:8080/pxe/rockylinux9 inst.ks=http://[PXE SERVER IP]:8080/pxe/ks.cfg
    initrdefi /rockylinux9/initrd.img
}
```
