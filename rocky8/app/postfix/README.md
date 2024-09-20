# Postfix
main.conf

## 1. Install

### 1.1 Install

    dnf -y install postfix
            
### 1.2 Edit for named.conf

    vi /etc/postfix/main.cf

### 1.3 Install rsyslog
     
    dnf -y install rsyslog
    
### 1.4 Edit vi /etc/rsyslog.conf for mail logging

    mail.*  /var/log/maillog

### 1.5 Check config
     
    rsyslogd -N 1

### 1.6 Run rsyslog
     
    systemctl enable --now rsyslog
    systemctl restart rsyslog

### 1.7 Run postfix
     
    systemctl enable --now postfix
    systemctl restart postfix
    
### 1.8 setting rules to firewalld

    firewall-cmd --zone=trusted --add-service=smtp
    
    firewall-cmd --runtime-to-permanent

## 2. Testing

### 2.1 Check config
    
    postconf -n

### 2.2 Sendmail

    dnf -y install mailx
    echo "test email" | mailx -s "Test email from Postfix MailServer" -r from@mail to@mail

### 2.3 Check logging

    tail -f /var/log/maillog

</hr>

## 3. Authenticated SMTP or Submission

### 3.1 Install with package
    
    dnf -y install cyrus-sasl-plain

### 3.2 Postfix config

```
vi /etc/postfix/main.cf

# Relayhost 설정: 외부 SMTP 서버를 지정합니다.
relayhost = [smtp.example.com]:25

# SASL 인증 설정
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_sasl_mechanism_filter = login
smtp_tls_security_level = none
header_size_limit = 4096000
```

### 3.3 SASL

```
vi /etc/postfix/sasl_passwd

[smtp.example.com]:25    your-email@example.com:your-password
```


### 3.4 Check config and create database

```
sudo chmod 600 /etc/postfix/sasl_passwd
sudo postmap /etc/postfix/sasl_passwd

```

### 3.5 Check logging

```
sudo systemctl restart postfix
sudo systemctl enable postfix

```

### 3.6 Test and check logging

```
echo "This is a test email." | mailx -s "Test Subject" recipient@example.com

sudo tail -f /var/log/maillog

```

### 3.7 Debug

```
sudo journalctl -u postfix

sudo postconf -n


```

## X. Useful Links

    https://
    
