## 1. Solr

### 1.1 Stop

    ~/solr/bin/solr stop

### 1.2 Need packages

```
dnf -y install rsync nfs-utils

vi /etc/idmapd.conf

Domain = qubitsec.internal

systemctl start rpcbind

```
## 2. Directory mount

### 2.1 Make NFS Disk Mount

    mkdir solrbackup

    sudo mount -t nfs 10.100.61.144:/home/nfsshare/109 /home/sysadmin/solrbackup

    sudo chown username.username solrbackup/

### 2.2 Change directory for Solr index from local to nfs mount directory

```
vi ./solr-data/weblog_shard1_replica_n482/core.properties

dataDir=/home/username/solrbackup

```
### 2.3 Run

    ~/solr/bin/solr start -cloud

## 3. Revoke

### 3.1 Index copy from nfs mount to local

    rsync -av /home/sysadmin/solrbackup/ /home/username/solr-data/weblog_shard1_replica_n482/data

### 3.2 

    rsync -av /home/sysadmin/solrbackup/ /home/username/solr-data/weblog_shard1_replica_n482/data

## 3. Check

### 3.1 Count files

    ls -l /home/nfsshare/97/index.20240118143136254/ | wc -l

## 4. unmount

### 4.1 Count files

    sudo reboot

    sudo umount /home/username/solrbackup/

    rm -rf solrbackup/

    sudo systemctl stop rpcbind


<hr/>

## X. References

#### x.1 https://www.server-world.info/en/note?os=Rocky_Linux_8&p=nfs&f=2
