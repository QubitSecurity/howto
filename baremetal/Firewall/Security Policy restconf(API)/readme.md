### 0.1 사전 설명
```
Security Policy(FW Rule) Restconf 
Restconf API 통신은 HTTPS 기반에서 동작하며, 기본 인증서가 설정되어 있음
Restconf API를 통해 Rule 적용에 따라 Rule data 업로드가 필요한 경우(Rule 생성, 변경 등) xml 형태로 업로드 가능
최초 장비 셋팅 시, restconf API를 활성화하고 접속 포트 확인(ex. 1025 등)
```

### 0.2 xml 파일 형식(예시)
```
<rule>
  <desc>just for test</desc>
  <source-zone>untrust</source-zone>
  <destination-zone>trust</destination-zone>
  <source-ip>
    <address-ipv4>192.168.1.1/32</address-ipv4>
  </source-ip>
  <destination-ip>
    <address-ipv4>1.1.1.0/24</address-ipv4>
  </destination-ip>
  <service>
    <service-object>http</service-object>
    <service-items>
      <tcp>
        <source-port>0 to 65535</source-port>
        <dest-port>80</dest-port>
      </tcp>
    </service-items>
  </service>

```
### 1. 설정 룰셋 생성
```
curl -v -k --tls-max 1.2  -u "<restconf_ID>:<restconf_PW>"  \
-X PUT "https://<Firewall_IP>:1025/restconf/data/huawei-security-policy:sec-policy/vsys=public/static-policy/rule=[Rule_Name]" \
-H "Content-Type: application/yang-data+xml" -H "Accept: application/yang-data+xml" -d @[Rule_Name].xml"
```

### 2. 설정 룰셋 변경
```
curl -v -k --tls-max 1.2  -u "<restconf_ID>:<restconf_PW>"  \
-X PUT "https://<Firewall_IP>:1025/restconf/data/huawei-security-policy:sec-policy/vsys=public/static-policy/rule=[Rule_Name]" \
-H "Content-Type: application/yang-data+xml" -H "Accept: application/yang-data+xml" -d @[Rule_Name].xml"
```

### 3. Rule 순서 처음에 룰 생성
```
curl -v -k --tls-max 1.2  -u "<restconf_ID>:<restconf_PW>"  \
-X PUT "https://<Firewall_IP>:1025/restconf/data/huawei-security-policy:sec-policy/vsys=public/static-policy/rule=[Rule_Name]?insert=first" \
-H "Content-Type: application/yang-data+xml" -H "Accept: application/yang-data+xml" -d @[Rule_Name].xml"
```

### 4. Rule 순서 마지막에 룰 생성
```
curl -v -k --tls-max 1.2  -u "<restconf_ID>:<restconf_PW>"  \
-X PUT "https://<Firewall_IP>:1025/restconf/data/huawei-security-policy:sec-policy/vsys=public/static-policy/rule=[Rule_Name]?insert=last" \
-H "Content-Type: application/yang-data+xml" -H "Accept: application/yang-data+xml" -d @[Rule_Name].xml"
```

### 5. 특정 룰 뒤에 생성
```
curl -v -k --tls-max 1.2  -u "<restconf_ID>:<restconf_PW>"  \
-X PUT "https://<Firewall_IP>:1025/restconf/data/huawei-security-policy:sec-policy/vsys=public/static-policy/rule=[Rule_Name]?insert=after&key=[name=’another_rule’]" \
-H "Content-Type: application/yang-data+xml" -H "Accept: application/yang-data+xml" -d @[Rule_Name].xml"
```

### 6. 특정 룰 앞에 생성
```
curl -v -k --tls-max 1.2  -u "<restconf_ID>:<restconf_PW>"  \
-X PUT "https://<Firewall_IP>:1025/restconf/data/huawei-security-policy:sec-policy/vsys=public/static-policy/rule=[Rule_Name]?insert=before&key=[name=’another_rule’]" \
-H "Content-Type: application/yang-data+xml" -H "Accept: application/yang-data+xml" -d @[Rule_Name].xml"
```

### 7. 특정 설정 룰셋 삭제
```
curl -v -k --tls-max 1.2  -u "<restconf_ID>:<restconf_PW>"  \
-X DELETE "https://<Firewall_IP>:1025/restconf/data/huawei-security-policy:sec-policy/vsys=public/static-policy/rule=[Rule_Name]
```


### 8. 룰 조회
```
전체 룰 조회
curl -v -k --tls-max 1.2  -u "<restconf_ID>:<restconf_PW>" \
-X GET "https://<Firewall_IP>:1025/restconf/data/huawei-security-policy:sec-policy"
특정 룰 조회
curl -v -k --tls-max 1.2  -u "<restconf_ID>:<restconf_PW>"  \
-X GET "https://<Firewall_IP>:1025/restconf/data/huawei-security-policy:sec-policy/vsys=public/static-policy/rule=web
```
