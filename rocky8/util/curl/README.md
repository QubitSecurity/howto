# cURL

## 1. Begin

### 1.1 curl

````
curl -v https://repo.plura.io

curl --noproxy '*' -v https://repo.plura.io

curl --noproxy '*' --insecure -v https://repo.plura.io
````

<hr/>

### 2.1 curl
````
curl --noproxy '*' -v http://blog.plura.io | more
````
### 2.1 X-Forwarded-For Header Injection
````
curl -H "X-Forwarded-For: 192.168.1.1" -v http://blog.plura.io | more
````

````

````




