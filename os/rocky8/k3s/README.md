## 1. K3s

### 1.1 master

```
curl -sfL https://get.k3s.io | sh -s - server \
  --cluster-init \
  --datastore-endpoint='mysql://k3s:password@tcp(10.10.11.229:3306)/k3s' > install.log 2>&1
```

### 1.2 add to master

```
curl -sfL https://get.k3s.io | K3S_TOKEN=<token> sh -s - server
--datastore-endpoint="mysql://k3s:password@tcp(10.10.11.229:3306)/k3s"
--server https://10.10.11.220:6443
```

### 1.3 Check nodes

```
kubectl get nodes
```

## 2. Register

### 2.1 Delete nodes

```
kubectl drain 011221-k3s-m --ignore-daemonsets --delete-local-data
kubectl delete node 011221-k3s-m
```

```

```
<hr/>

### 2.2 Register for http_check

```

```

### 2.3 Restart

```
systemctl restart nagios
```

<hr/>


## X. Useful Links

- https://www.server-world.info/en/note?os=CentOS_Stream_8&p=nagios&f=1
