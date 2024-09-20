# nfs

## 1. Install NFS Server

### 1.1 Install

    dnf -y install nfs-utils

### 1.2 Make directory

    mkdir -p /home/nfsshare

### 1.3 Config
```
vi /etc/idmapd.conf
    
Domain = qubitsec.com
```
```
vi /etc/exports

/home/nfsshare 10.10.10.0/23(rw,no_root_squash)
```
### 1.4 Restart

    systemctl enable --now rpcbind nfs-server

    systemctl restart rpcbind
    systemctl restart nfs-server

## 2. Install NFS Client

### 2.1 Install

    dnf -y install nfs-utils

### 2.2 Config

    vi /etc/idmapd.conf
    
    Domain = qubitsec.com

### 2.3 Mount
```
mount -t nfs 10.10.11.14:/home/nfsshare /home/username/solrbackup
```
```
df -hT
df -hT /home/username/solrbackup
```
### 2.3 Mount
    umount /home/username/solrbackup

### 2.4 Configure AutoFS
```
dnf -y install autofs
```
```    
vi /etc/auto.master

# add to the end
/-    /etc/auto.mount
```
```    
vi /etc/auto.mount

/home/username/solrbackup   -fstype=nfs,rw  10.10.11.14:/home/nfsshare
```

### 2.4 Restart

    systemctl enable --now autofs

## 3. Firewall

### 3.1 Config
```
firewall-cmd --add-service=nfs
    
firewall-cmd --add-service={nfs3,mountd,rpc-bind}
        
firewall-cmd --runtime-to-permanent
```    
## 4. Useful Links

    https://www.server-world.info/en/note?os=Rocky_Linux_8&p=nfs&f=1


## 5. Example for nfs client config

![nfs_vmware](https://github.com/QubitSecurity/documentation/assets/24949168/06f2608a-bbc0-4dd0-8257-db4a87847fe5)
