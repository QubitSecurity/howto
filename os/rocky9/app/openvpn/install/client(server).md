## 설치 사항
```
클라이언트 시스템(서버) openvpn 클라이언트 설정
```

### 1. openvpn 설치
```
sudo dnf install -y epel-release
sudo dnf install -y openvpn
```

### 2. 클라이언트 설정 파일 작성
```
vi /etc/openvpn/client/client.conf
client.conf 참고
```

### 3. 시작
```
수동 시작
sudo openvpn --config /etc/openvpn/client/client.ovpn

systemd 설정
sudo systemctl enable openvpn-client@client
sudo systemctl start openvpn-client@client
```
