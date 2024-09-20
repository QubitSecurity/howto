nmcli connection add type bridge autoconnect yes con-name bridge0 ifname bridge0

nmcli connection modify bridge0 ipv4.addresses 10.10.11.10/23 ipv4.method manual

nmcli connection modify bridge0 ipv4.dns 10.10.10.250

nmcli connection del enp2s0f0

nmcli connection add type bridge-slave autoconnect yes con-name enp2s0f0 ifname enp2s0f0 master bridge0

reboot
