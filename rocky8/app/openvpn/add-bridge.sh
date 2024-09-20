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
