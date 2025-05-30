## 0. 사전 설명
PXE 부팅으로 다른 시스템 OS 설치<br>
dhcp와 tftp, httpd 를 같은 서버에서 동작하고 OS iso 파일 마운트

<br><br>
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
# 대역 10.10.11.0/24
# 할당 범위 10.10.11.240~243
subnet 10.10.11.0 netmask 255.255.255.0 {
        option routers 10.10.10.1;
        range 10.10.11.240 10.10.11.243;
        filename "pxelinux.0";
        next-server 10.10.11.253; #tftp 서버(동일)
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
mkdir /var/www/html/pxe/rockylinux8
mount -t iso9660 -o loop,ro /root/pxe_iso_files/Rocky-*-x86_64-dvd1.iso /var/www/html/pxe/rockylinux8
systemctl restart httpd
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
 menu label ^1) Install Rocky Linux 8
 menu default
 kernel rockylinux8/vmlinuz
 append initrd=rockylinux8/initrd.img ip=dhcp inst.repo=http://[SERVER_IP]:8080/pxe/rockylinux8

```


