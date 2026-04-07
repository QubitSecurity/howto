nmcli connection add type bridge autoconnect yes con-name br0 ifname br0

nmcli connection modify br0 ipv4.addresses 172.16.16.100/12 ipv4.method manual

nmcli connection modify br0 ipv4.gateway 172.16.0.1

nmcli connection modify br0 ipv4.dns 172.16.10.250

nmcli connection del enp2s0f0

nmcli connection add type bridge-slave autoconnect yes con-name enp2s0f0 ifname enp2s0f0 master br0

reboot
