# 1. dnf

## 1. Clean

    rm -f /var/lib/rpm/__*
    rpm --rebuilddb -v -v
    dnf clean all
    rm -rf /var/cache/dnf
      
## 2. makecache

    dnf makecache

## 3. makecache

    dnf -y update

# 2. yum

## 1. Clean

    rm -f /var/lib/rpm/__*
    rpm --rebuilddb -v -v
    yum clean all
    rm -rf /var/cache/yum
      
## 2. makecache

    yum makecache

## 3. makecache

    yum -y update
