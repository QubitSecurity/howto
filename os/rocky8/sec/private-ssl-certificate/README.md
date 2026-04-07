# Create Your Own SSL Certificate Authority for Local HTTPS Development
   
## 1. Issuance of ROOT CA certificate


### 1.1 CA RSA Key pair

    openssl genrsa -aes256 -out plura-rootca.key 2048
    
### 1.2 Edit rootca_openssl.conf

    vi rootca_openssl.conf
    
### 1.3 Create CSR for Root CA

    openssl req -new -key plura-rootca.key -out plura-rootca.csr -pluraig rootca_openssl.plura
    
### 1.4 Create self-singed for 10 years

    openssl x509 -req -days 3670 -extensions v3_ca -set_serial 1 -in plura-rootca.csr -signkey plura-rootca.key -out plura-rootca.crt -extfile rootca_openssl.plura
    
### 1.5 verification

    openssl x509 -text -in plura-rootca.crt
    
## 2. Issuance of SSL certificate


### 2.1 Issuance RSA Key pair for host server

    openssl genrsa -aes256 -out plura.io.key 2048
    
### 2.2 Remove Passphrase from key

    cp plura.io.key  plura.io.key.enc
    
    openssl rsa -in  plura.io.key.enc -out plura.io.key

### 2.3 Edit host_openssl.conf

    vi host_openssl.conf
    
### 2.4 Create CSR

    openssl req -new -key plura.io.key -out plura.io.csr -config host_openssl.conf
    
### 2.5 Create self-singed for 10 years

    openssl x509 -req -days 3670 -extensions v3_user -in plura.io.csr -CA plura-rootca.crt -CAcreateserial -CAkey  plura-rootca.key -out plura.io.crt  -extfile host_openssl.conf
    
### 2.6 verification

    openssl x509 -text -in plura.io.crt

## 3. Merge

### 3.1 Make a pem file for Haproxy SSL

    cat plura.io.key plura.io.crt > plura.io.pem
    
    cat plura.io.pem

## X. Useful Links

- https://www.lesstif.com/system-admin/openssl-root-ca-ssl-6979614.html
- https://qubitsec.github.io/ko_plura_root_ca.html
    
    
    
