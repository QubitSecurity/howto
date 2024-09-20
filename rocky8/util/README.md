# Utilities


## 1. Begin
          
### 1.1 number of lines in file

    cat filename | wc -l
    
### 1.2 Check Remote Ports

    dnf install nc
    
    nc -zv 192.168.1.15 22
    
    nc -zv 192.168.56.10 20-80

### 1.3 Check Remote Ports with UDP

    nc -zv -u 192.168.56.10 5514

### 1.4 Check Disk : SSD or HDD

    cat /sys/block/sda/queue/rotational

- SSD: 0, HDD: 1

## 2. Hostname

### 2.1 Set System Hostname

    hostnamectl set-hostname 010010-kvm

### 2.2 Set System Locale

    localectl set-locale LANG=ko_KR.utf8

## 3. Proxy

### 3.1 create new

    vi /etc/profile.d/pproxy.sh

### 3.2 run

    source /etc/profile.d/pproxy.sh ls -l | awk '{ print $9 }'

## 4. ls

### 4.1 print only filename

    ls -l | awk '{ print $9 }'

## 5. Disk performance

### 5.1 SSD

    dnf -y install fio

    fio --name=rand-write --ioengine=libaio --iodepth=32 --rw=randwrite --bs=4k --direct=1 --size=1G --numjobs=1 --runtime=60 --group_reporting

## X. Useful Links

- https://www.tecmint.com/check-remote-port-in-linux/
- https://appuals.com/check-ram-slots-linux/
- https://gigglehd.com/gg/soft/6266879
