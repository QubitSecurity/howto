# Mysql
> https://dev.mysql.com/downloads/repo/yum/

## 1. Install

### 1.1 Install

    dnf install https://repo.mysql.com/mysql80-community-release-el8-9.noarch.rpm

    dnf module -y install mysql:8.0

    systemctl enable --now mysqld
 
### 1.2 Config

    mysql_secure_installation

### 1.3 Login

    mysql -p
    

### 1.4 vi /etc/my.cnf.d/charset.cnf

    [mysqld]
    character-set-server = utf8mb4
    
    [client]
    default-character-set = utf8mb4

### 1.5 Restart

    systemctl status mysqld
    systemctl restart mysqld

### 1.6 Check character set

    mysql -p
    
    mysql> show variables like 'char%';p

### 1.7 Setting rules to firewalld

    firewall-cmd --permanent --zone=public --add-port=3306/tcp
    firewall-cmd --permanent --zone=public --add-port=33060/tcp
    
    firewall-cmd --runtime-to-permanent
    firewall-cmd --reload

## 2. Clone

### 2.1 Clone

    virt-clone --original 24GBMSA --name mysql --file /var/lib/libvirt/images/mysql.qcow2

### 2.2 Generating uuid for new mysql

    uuidgen
    
    1b58f12d-5fec-11ed-bc07-000c29f03601

### 2.3 Edit

    vi /var/lib/mysql/auto.cnf
    
    [auto]
    server-uuid=1b58f12d-5fec-11ed-bc07-000c29f03601

## 3. Replication for error

### 3.1 Master

    mysql -uUser -p
    
    show master status;

### 3.2 Slave

    show slave status \G;
    
    STOP SLAVE;

    SET GLOBAL SQL_SLAVE_SKIP_COUNTER=1;

    START SLAVE;

### 3.3 Slave
    
    STOP SLAVE;

    CHANGE MASTER TO MASTER_LOG_FILE='mysql-bin.000023', MASTER_LOG_POS=157;

    START SLAVE;

    show slave status \G;    

### 3.4 Master with mysql

    FLUSH TABLES WITH READ LOCK;

    RESET MASTER;

    SHOW MASTER STATUS;

### 3.5 Master with shell

    mysqldump -uUser -p --events --triggers --routines --all-databases > dump-today.sql

    scp dump-today.sql to slave mysql

### 3.6 Master with mysql

    UNLOCK TABLES;

### 3.7 Slave with mysql
   
    STOP SLAVE;
    RESET SLAVE;
    
### 3.8 Slave with shell
   
    mysql -uUser -p < dump-today.sql

### 3.9 Slave with mysql
   
    CHANGE MASTER TO MASTER_HOST='10.10.10.000', MASTER_USER='repl', MASTER_PASSWORD='password', MASTER_LOG_FILE='mysql-bin.000001', MASTER_LOG_POS=157;

    START SLAVE;

    show slave status \G;

### X. Useful Links

> https://www.server-world.info/en/note?os=CentOS_Stream_8&p=mysql8&f=1


