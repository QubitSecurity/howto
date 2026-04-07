nmcli con mod br0 ipv6.method disabled
nmcli con down br0 
nmcli con up br0

nmcli con mod bridge0 ipv6.method disabled
nmcli con down bridge0
nmcli con up bridge0
