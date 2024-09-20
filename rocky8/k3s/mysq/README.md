## 1. mysql

### 1.1 master

```
dnf install mysql

mysql -u root -p
```

### 1.2 add to master

```
CREATE USER 'k3s'@'10.10.11.229' IDENTIFIED BY 'password';

GRANT ALL PRIVILEGES ON k3s.* TO 'k3s'@'10.10.11.229';

FLUSH PRIVILEGES;

EXIT;

```

### 1.3 Change password

```
ALTER USER 'k3s'@'10.10.11.229' IDENTIFIED BY 'new_password';

```
