# Haproxy

## 1. [INSTALL](https://github.com/QubitSecurity/howto/blob/main/rocky9/app/haproxy/install.md)

## 2. Master-Backup Config

### 2.1 INTERFACE
- Configuration Path: `/etc/NetworkManager/system-connections/`
- [Public](https://github.com/QubitSecurity/howto/blob/main/rocky9/app/haproxy/config/enp7s0.nmconnection)
- [Private](https://github.com/QubitSecurity/howto/blob/main/rocky9/app/haproxy/config/enp1s0.nmconnection)

### 2.2 Keepalived
- Configuration Path: `/etc/keepalived/`
- [Master](https://github.com/QubitSecurity/howto/blob/main/rocky9/app/haproxy/config/keepalived-master.conf)
- [Backup](https://github.com/QubitSecurity/howto/blob/main/rocky9/app/haproxy/config/keepalived-backup.conf)


### 2.3 PLURA
- [Proxy](https://github.com/QubitSecurity/howto/blob/main/rocky9/app/haproxy/config/pproxy.sh)
  - Configuration Path: `/etc/profile.d/pproxy.sh`
- [Daemon](https://github.com/QubitSecurity/howto/blob/main/rocky9/app/haproxy/config/plurad.service)
  - Configuration Path: `/lib/systemd/system/plurad.service`
