### 0. 사전 설명
```
Security Policy(FW Rule) Restconf 
Restconf API 통신은 HTTPS 기반에서 동작하며, 기본 인증서가 설정되어 있음
Restconf API를 통해 Rule 적용에 따라 Rule data 업로드가 필요한 경우(Rule 생성, 변경 등) xml 형태로 업로드 가능
```

### 0. xml 파일 형식
```
<rule>
  <desc>just for test</desc>
  <source-zone>untrust</source-zone>
  <destination-zone>trust</destination-zone>
  <source-ip>
    <address-ipv4>192.168.10.11/32</address-ipv4>
  </source-ip>
  <destination-ip>
    <address-ipv4>10.10.12.0/24</address-ipv4>
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
### 설정 룰셋 생성
```
curl -v -k -u "<restconf_ID>:<restconf_PW>"  -X PUT "https://<Firewall_IP>:1025/restconf/data/huawei-security-policy:sec-policy/vsys=public/static-policy/rule=test" -H "Content-Type: application/yang-data+xml" -H "Accept: application/yang-data+xml" -d @test.xml"
```
