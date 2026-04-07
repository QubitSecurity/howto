## 1. WordPress

### 1.1

```
dnf -y install epel-release

dnf install https://rpms.remirepo.net/enterprise/remi-release-8.rpm

dnf -y install php:remi-7.4
dnf module list php
dnf module reset php
dnf module enable php:remi-7.4
dnf module -y install php:remi-7.4/common

php -v
```

### 1.2
```
dnf install php php-mysqlnd

systemctl restart php-fpm
systemctl restart nginx
```

### 1.3 Download

```
wget https://ko.wordpress.org/latest-ko_KR.tar.gz

wget https://www.wordpress.org/latest.tar.gz
```

## 2.

### 2.1

```
dnf install php-gd php-imagick php-intl php-zip
dnf install php-curl php-openssl
```
<hr/>

### 2.2 create database

```
CREATE DATABASE wp_database_name DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;

CREATE USER 'username'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON wp_database_name.* TO 'username'@'localhost';
FLUSH PRIVILEGES;
```


```
UPDATE wp_options SET option_value = 'https://blog.plura.io' WHERE option_name = 'home' OR option_name = 'siteurl';
```

<hr/>

### 2.3 Test about proxy configuration

```
curl -I https://example.com
```

```
vi proxy-test.php

<?php
/**
 * WordPress 프록시 테스트 스크립트.
 */

// WordPress 환경 불러오기.
require('wp-blog-header.php');

$response = wp_remote_get('https://example.com');

if (is_wp_error($response)) {
    echo '연결 실패: ', $response->get_error_message();
} else {
    echo '연결 성공: ', wp_remote_retrieve_body($response);
}
```

<hr/>


## X. Useful Links

- https://www.server-world.info/en/note?os=CentOS_Stream_8&p=nginx&f=7
