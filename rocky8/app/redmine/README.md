# Redmine
chrony conf

## 1. Mysql

### 1.1 Install

    dnf -y install chrony
            

## 2. Copy

### 2.1 private key

    yum groupinstall "Development Tools"

    yum install git curl glibc-headers autoconf automake bison gcc-c++ libffi-devel libtool readline-devel sqlite-devel zlib-devel openssl-devel
    

## 3. Basic commands

### 3.1 ping

    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
    echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
    source ~/.bash_profile

    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
    echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bash_profile
    source ~/.bash_profile

### 3.2 Copy for NTP

    dnf install libffi-devel -y
    
    rbenv install -l
    rbenv install 3.2.2

### 3.3 Run

    dnf config-manager --set-enabled powertools
    dnf --enablerepo=powertools install libyaml-devel libffi-devel

### 3.4 Check

    rbenv install 3.2.2
    rbenv global 3.2.2
    ruby -v

### 3.3 Run

    gem install bundler
    gem update --system 3.5.4

### 3.4 Check

    gem search '^rails$' --all
    gem install rails -v 6.1.7.6
    rbenv rehash
    rails -v

    
## 5. HTTP

### 1.1 Install

    dnf -y install chrony
