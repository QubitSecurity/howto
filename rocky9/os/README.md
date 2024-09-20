# Rocky 9

### 0.4 sudoers

```
cp -f /etc/sudoers /etc/sudoers.bak
```
```
awk 'NR==111{print "user        ALL=(ALL)       NOPASSWD: ALL"}113' /etc/sudoers.bak > /etc/sudoers
```
```
cat /etc/sudoers | grep user
```
## Disable IPv6

```
grubby --update-kernel ALL --args ipv6.disable=1
```

```
sysctl -w net.ipv6.conf.all.disable_ipv6 = 1
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
```

## Enable cockpit
default port: 9090
```
systemctl enable --now cockpit.socket
```

# Add Additional Repositories

## Add EPEL that Fedora project

```
dnf -y install epel-release
```

## Add Remi's RPM repository

```
dnf -y install https://rpms.remirepo.net/enterprise/remi-release-9.rpm
```

```
rpm -ql remi-release

grep 'enabled=1' /etc/yum.repos.d/remi-*
```

## OS Download

- https://mirror.navercorp.com/rocky/9/isos/x86_64/

## Useful Link
- https://ftp.kaist.ac.kr/pub/epel/9/Everything/

- https://www.server-world.info/en/note?os=CentOS_Stream_9&p=initial_conf&f=7

