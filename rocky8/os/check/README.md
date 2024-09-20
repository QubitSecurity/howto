## 1. Error
    
### 1.1 systemd-tmpfiles-setup.service

    systemctl status systemd-tmpfiles-setup.service

## 2. OS Version

### 2.1 OS

    cat /etc/*-release | uniq
    
    grep . /etc/*-release

## 3. CPU

### 3.1 CPU core Counts

    grep -c processor /proc/cpuinfo
    
    grep "physical id" /proc/cpuinfo | sort -u
    
    grep "cpu cores" /proc/cpuinfo | tail -1
    
## 4. Memory

### 4.1 run dmidecode

    dmidecode -t 16

    dmidecode -t 17

    dmidecode -t memory | grep Error

### 4.2 run lshw

    lshw -class memory
    
    lshw -class memory | grep size

### 4.3 using rasdaeomn

    rasdaemon --record

    ras-mc-ctl --summary

    ras-mc-ctl --errors

    ras-mc-ctl --layout

    ras-mc-ctl --mainboard

    ras-mc-ctl --status

    ras-mc-ctl --print-labels

    ras-mc-ctl --guess-labels

### 4.4 Cache clear

    sync
    sync
    sync

    echo 1 > /proc/sys/vm/drop_caches

    echo 2 > /proc/sys/vm/drop_caches

    echo 3 > /proc/sys/vm/drop_caches


## X. Useful Links

- https://zetawiki.com/wiki/%EB%A6%AC%EB%88%85%EC%8A%A4_%EC%A2%85%EB%A5%98_%ED%99%95%EC%9D%B8,_%EB%A6%AC%EB%88%85%EC%8A%A4_%EB%B2%84%EC%A0%84_%ED%99%95%EC%9D%B8 
    
