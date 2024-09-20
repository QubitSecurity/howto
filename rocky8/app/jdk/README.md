# OPEN JDK
OPEN JDK

## 1. Install

### 1.1 Install JDK 8

    dnf -y install java-1.8.0-openjdk java-1.8.0-openjdk-devel
    
    java -version
            
### 1.2 Install JDK 11

    dnf -y install java-11-openjdk java-11-openjdk-devel
    
    java -version

### 1.3 Install JDK 17
````
dnf -y install java-17-openjdk java-17-openjdk-devel
````
````
cat > /etc/profile.d/java.sh <<'EOF'
export JAVA_HOME=$(dirname $(dirname $(readlink $(readlink $(which java)))))
export PATH=$PATH:$JAVA_HOME/bin
EOF
````

````
source /etc/profile.d/java.sh

java -version
````

### 1.3 Alternative

    alternatives --config java
    
    alternatives --config javac

## 2. Packages

### 2.1 Groupinstall for Development Tools

    dnf -y groupinstall 'Development Tools'

### 2.2 compate openssl10

    openssl version -a
    
    dnf -y install compat-openssl10

## 3. Remove

### 3.1 Remove jdk-8

    dnf remove java-1.8.0-openjdk java-1.8.0-openjdk-devel java-1.8.0-openjdk-headless

## X. Useful Links

    https://www.server-world.info/en/note?os=CentOS_Stream_8&p=java&f=1
    https://www.server-world.info/en/note?os=CentOS_Stream_8&p=java&f=2
