# Redis


## 1. Preconfig

### 1.1 vi /etc/sysctl.conf

    fs.file-max = 2097152
    
    net.ipv4.ip_local_port_range = 1024 65500
    net.core.rmem_default = 26214400
    net.core.rmem_max = 26214400
    net.core.wmem_default = 262144
    net.core.wmem_max = 1048576
    
    vm.overcommit_memory = 1
            
### 1.2 transparent_hugepage

    echo never > /sys/kernel/mm/transparent_hugepage/enabled

### 1.3 vi /etc/security/limits.conf

    echo "redis   soft    nofile  65535" >> /etc/security/limits.conf
    echo "redis   hard    nofile  65535" >> /etc/security/limits.conf

## 2. Install

### 2.1 Install redis

    dnf module list redis
    
    dnf module -y install redis:6
            
### 2.2 vi /etc/redis.conf

    chown redis.root /etc/redis-6379.conf
    chown redis.root /etc/redis-6381.conf
    chown redis.root /etc/redis-6383.conf

### 2.3 set config

    touch /var/lib/redis/nodes-6381.conf
    touch /var/lib/redis/nodes-6383.conf

    chown -R redis.redis /var/lib/redis/nodes-6381.conf
    chown -R redis.redis /var/lib/redis/nodes-6383.conf

### 2.4 Run redis

    systemctl enable --now redis
    
    ps -ef | grep redis

## 3. Selinux & Firewalld

### 3.1 Selinux (generally unnecessary)

    dnf -y install policycoreutils-python-utils

    semanage port -l | grep redis_port_t
    
    semanage port -a -t redis_port_t -p tcp 6381
    semanage port -a -t redis_port_t -p tcp 16381

    semanage port -a -t redis_port_t -p tcp 6383
    semanage port -a -t redis_port_t -p tcp 16383

    semanage port -a -t redis_port_t -p tcp 26381
    semanage port -a -t redis_port_t -p tcp 26383   

### 3.2 Firewalld

    firewall-cmd --add-port=6379/tcp
    
    firewall-cmd --add-port=16379/tcp
    
    firewall-cmd --runtime-to-permanent


## 4. Clone

### 4.1 Clone

    virt-clone --original 010050-redis --name 010051-redis --file /var/lib/libvirt/images/010051-redis.qcow2
    
    virt-clone --original 010050-redis --name 010052-redis --file /var/lib/libvirt/images/010052-redis.qcow2

### 4.2 Set up IP Address

    virsh start 010051-redis --console
    
    virsh start 010052-redis --console

## 5. Cluster

### 5.1 Create

    redis-cli --cluster create 10.10.10.50:6379 10.10.10.51:6379 10.10.10.52:6379
    
    redis-cli --cluster check 10.10.10.50:6379
    
    redis-cli -c -h 10.10.10.50 -p 6379 CLUSTER NODES
    
    systemctl restart redis

### 5.2 Testing

    redis-cli -h 10.10.10.50 -p 6379
    
    redis-cli -h 10.10.10.51 -p 6379
    
    redis-cli -h 10.10.10.52 -p 6379
    
    redis-cli -c -h 10.10.10.50 -p 6379 CLUSTER NODES
    
    redis-cli --cluster check 10.10.10.50:6379

### 5.3 Reset

    redis-cli -h 10.10.10.50 -p 6379
    > flushall
    
    redis-cli -h 10.10.10.51 -p 6379
    > flushall
    
    redis-cli -h 10.10.10.52 -p 6379
    > flushall

### X. Useful Links

    https://www.server-world.info/en/note?os=CentOS_Stream_8&p=redis6&f=1
