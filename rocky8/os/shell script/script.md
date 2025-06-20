## shell script 전체 코드 
- (IP 변경, Hostname 변경, ssh 포트 변경) 
- bash shell 사용


```
#!/bin/bash
set -euo pipefail

[[ $# -ne 3 ]] && { echo "Usage: $0 <IP/CIDR> <Gateway> <Hostname>"; exit 1; }

ip_cidr="$1"
gw="$2"
host="$3"

# 인터페이스 이름 가져오기 (기본 라우팅 기준)
iface=$(ip route get 1.1.1.1 | awk '{print $5; exit}')
[[ -z "$iface" ]] && {
  echo "No network interface found."
  exit 1
}


# 연결 이름 가져오기 (nmcli에서 인터페이스에 해당하는 연결 이름 찾기)
con_name=$(nmcli -t -f NAME,DEVICE con show --active | grep ":$iface" | cut -d: -f1)
[[ -z "$con_name" ]] && {
  echo "No active connection found for interface $iface"
  exit 1
}

echo -e "\n[Network Info]"
echo "Interface   : $iface"
echo "Connection  : $con_name"
echo "New IP      : $ip_cidr"
echo "Gateway     : $gw"
echo "Hostname    : $host"

### IP 및 Gateway 설정 (영구)
echo -e "\n[Updating Network Configuration]"
nmcli con mod "$con_name" ipv4.addresses "$ip_cidr"
nmcli con mod "$con_name" ipv4.gateway "$gw"
nmcli con mod "$con_name" ipv4.method manual
nmcli con mod "$con_name" connection.autoconnect yes

# DNS 예시 (필요 시)
nmcli con mod "$con_name" ipv4.dns "10.10.92.250"

# 적용
#nmcli con down "$con_name" && nmcli con up "$con_name"

### Hostname
echo -e "\n[Hostname]"
current_host=$(hostname)

if [[ "$host" != "$current_host" ]]; then
  echo "$host" | sudo tee /etc/hostname >/dev/null
  sudo hostnamectl set-hostname "$host"
  sudo sed -i "s/127\.0\.1\.1.*/127.0.1.1 $host/" /etc/hosts
  echo "Hostname   	: Changed to $host"
else
  echo "Hostname   	: Unchanged"
fi

### SSH
#!/bin/bash
port=41
conf="/etc/ssh/sshd_config"

echo -e "\n[SSH Configuration]"
echo "[*] Checking SSH port settings..."

grep -q "^Port $port$" "$conf" && sshd_ok=1 || sshd_ok=0
sudo semanage port -l | grep -qE "^ssh_port_t.*\b$port\b" && selinux_ok=1 || selinux_ok=0
sudo firewall-cmd --list-ports | grep -q "${port}/tcp" && fw_ok=1 || fw_ok=0

[[ $sshd_ok -eq 1 ]] && echo "[OK] sshd_config  : set"  	|| echo "[FAIL] sshd_config  : not set"
[[ $selinux_ok -eq 1 ]] && echo "[OK] SELinux  	: registered" || echo "[FAIL] SELinux  	: not registered"
[[ $fw_ok -eq 1 ]] && echo "[OK] firewalld	: open" 	|| echo "[FAIL] firewalld	: not open"

if [[ $sshd_ok -eq 0 || $selinux_ok -eq 0 || $fw_ok -eq 0 ]]; then

  [[ $sshd_ok -eq 0 ]] && {
	# Remove any existing Port lines and append a clean one
	sudo sed -i '/^Port /d' "$conf"
	echo "Port $port" | sudo tee -a "$conf" >/dev/null
	echo "[+] Port $port added to sshd_config"
  }

  [[ $selinux_ok -eq 0 ]] && {
	sudo semanage port -a -t ssh_port_t -p tcp "$port" 2>/dev/null || true
	echo "[+] SELinux port updated"
  }

  [[ $fw_ok -eq 0 ]] && {
	sudo firewall-cmd --permanent --add-port=$port/tcp
	sudo firewall-cmd --permanent --remove-port=22/tcp || true
	echo "[+] firewalld port updated"
  }

  sudo firewall-cmd --reload
  sudo systemctl restart sshd

  echo -e "\nSSH port updated. Use: ssh -p $port user@host"

else
  echo -e "\nSSH already set to port $port. Use: ssh -p $port user@host"
fi

echo -e "\nAll changes applied."

sudo firewall-cmd --permanent --zone=trusted --add-source=10.10.92.0/22
sudo firewall-cmd --reload

sleep 3
sudo reboot

```

