
## 0. 사전 작업
### 0.1 epel 레포지토리 설치
```
dnf install epel-release
```
### 0.2 관련 유틸리티 설치
```
dnf --enablerepo=epel install openvpn easy-rsa net-tools
```
### 0.3 사설 CA 구성
```
사설 CA 구성
cd /usr/share/easy-rsa/3

initialize
easyrsa init-pki

# create CA
easyrsa build-ca

# set any name
Common Name (eg: your user, host, or server name) [Easy-RSA CA]:PLURA-CA

easyrsa build-server-full server1 nopass

# generate Diffie Hellman ( DH ) parameter
easyrsa gen-dh

# create TLS-Auth key
openvpn --genkey --secret ./pki/ta.key
```

## 1. openvpn 설정
### 1.1 생성된 CA 및 인증서 복사
```
cp -pR /usr/share/easy-rsa/3/pki/{issued,private,ca.crt,dh.pem,ta.key} /etc/openvpn/server/
```

### 1.2 config 파일 수정
```
vi /etc/openvpn/server/server.conf
```

### 1.3 NW bridge 설정
```
mkdir /etc/openvpn/scritps/

vi /etc/openvpn/scripts/add-bridge.sh
#!/bin/bash

# network interface which can connect to local network
IF=enp1s0
# interface VPN tunnel uses
# for the case of this example like specifying [tun] on the config, generally this param is [tun0]
VPNIF=tun0
# listening port of OpenVPN
PORT=1194

firewall-cmd --zone=trusted --add-masquerade
firewall-cmd --direct --add-rule ipv4 filter FORWARD 0 -i ${VPNIF} -o ${IF} -j ACCEPT
firewall-cmd --direct --add-rule ipv4 nat POSTROUTING 0 -o ${IF} -j MASQUERADE
firewall-cmd --add-port=${PORT}/udp


vi /etc/openvpn/scripts/remove-bridge.sh
#!/bin/bash

# network interface which can connect to local network
IF=enp1s0
# interface VPN tunnel uses
# for the case of this example like specifying [tun] on the config, generally this param is [tun0]
VPNIF=tun0
# listening port of OpenVPN
PORT=1194

firewall-cmd --zone=trusted --remove-masquerade
firewall-cmd --direct --remove-rule ipv4 filter FORWARD 0 -i ${VPNIF} -o ${IF} -j ACCEPT
firewall-cmd --direct --remove-rule ipv4 nat POSTROUTING 0 -o ${IF} -j MASQUERADE
firewall-cmd --remove-port=${PORT}/udp

chmod 700 /etc/openvpn/scritps/{add-bridge.sh,remove-bridge.sh}
```


### 1.4 openvpn 서비스 설정
```
mkdir /etc/systemd/system/openvpn-server@server.service.d
vi /etc/systemd/system/openvpn-server@server.service.d/override.conf
[Service]
ExecStartPost=/etc/openvpn/scritps/add-bridge.sh
ExecStopPost=/etc/openvpn/scritps/remove-bridge.sh
```


## 2. 방화벽 설정
### 2.1 기본 zone 확인
```
firewall-cmd --get-default-zone
firewall-cmd --get-active-zones
```

### 2.2 trusted zone 인터페이스 설정
```
firewall-cmd --permanent --zone=trusted --add-interface=enp1s0
```

### 2.3 규칙 설정
```
firewall-cmd --permanent --zone=public --add-port=1194/udp
firewall-cmd --permanent --zone=public --add-port=1194/tcp
firewall-cmd --reload
```

### 2.4 Selinux 설정
```
chcon -u system_u /etc/openvpn/scripts/add-bridge.sh
chcon -u system_u /etc/openvpn/scripts/remove-bridge.sh

ls -Z /etc/openvpn/scripts/add-bridge.sh

grep "type=AVC" /var/log/audit/audit.log

grep "type=AVC" /var/log/audit/audit.log | audit2allow -a -M openvpn_rule

semodule -i openvpn_rule.pp
```


## 3. 사용자 인증서 생성
```
easyrsa build-client-full Client1

mkdir /root/Client1
cp /usr/share/easy-rsa/3/pki/private/Client1.key /root/Client1
cp /usr/share/easy-rsa/3/pki/issued/Client1.crt /root/Client1
cp /etc/openvpn/scripts/ta.key /root/Client1

zip -xi Client1.zip ca.crt Client1.crt Client1.key ta.key
```
