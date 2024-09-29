## 1. Solr

### 1.0 Config

```
vi /etc/security/limits.conf

username              soft    nofile  65536
username              hard    nofile  65536
username              soft    nproc   unlimited
username              hard    nproc   unlimited
```

### 1.1 Run and Stop
```
~/solr/bin/solr start -cloud
```
```
~/solr/bin/solr stop
```
<hr/>

```
vi ~/solr/bin/solr.in.sh

#SOLR_HEAP="512m"
SOLR_HEAP="16g"

# Add to end
# Zookeeper config
. /home/$("whoami")/solr_zookeeper/*.conf
```

<hr/>
