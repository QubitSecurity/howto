Rocky Linux 8에서 TCP 에러를 커널 레벨에서 확인하려면, 여러 도구와 커맨드를 통해 TCP 관련 문제를 추적할 수 있습니다. 특히 커널 로그와 네트워크 상태를 모니터링하는 도구들이 유용합니다. 아래는 TCP 에러를 커널 레벨에서 확인하는 방법들입니다:

### 1. **커널 로그 확인**
TCP 관련 오류가 발생했을 때 커널에서 로그가 남을 수 있습니다. 커널 로그는 `dmesg` 명령어를 사용하여 확인할 수 있습니다.

```bash
dmesg | grep -i tcp
```

이 명령어는 커널 로그에서 'TCP'와 관련된 메시지를 필터링하여 보여줍니다. 만약 TCP 관련 에러가 발생했다면 이 로그에서 확인할 수 있습니다.

또는 `/var/log/messages` 또는 `/var/log/syslog`에서 네트워크 오류 관련 로그를 검색할 수도 있습니다.

```bash
sudo grep -i tcp /var/log/messages
```

### 2. **Netstat 혹은 ss 명령어 사용**
TCP 연결 상태와 에러를 확인하기 위해 `netstat` 또는 `ss` 명령어를 사용할 수 있습니다.

- `ss` 명령어로 TCP 연결 상태를 모니터링:

```bash
ss -s
```

이 명령어는 시스템의 TCP 통계 정보를 보여줍니다. 패킷 손실, 재전송 등 TCP 에러에 대한 힌트를 얻을 수 있습니다.

- `netstat` 명령어로 TCP 소켓 상태 확인:

```bash
netstat -s | grep -i tcp
```

이 명령어는 TCP 관련 통계를 출력하며, 에러가 발생한 횟수나 연결 상태를 확인할 수 있습니다.

### 3. **Network Monitoring with `tcpdump`**
`tcpdump`는 패킷 수준에서 네트워크 트래픽을 캡처하여 문제를 진단하는 데 사용됩니다.

```bash
sudo tcpdump -i eth0 tcp
```

특정 인터페이스(여기서는 `eth0`)에서 TCP 패킷을 캡처하여 분석할 수 있습니다. TCP 핸드셰이크 실패, 패킷 재전송, 패킷 손실 등을 확인할 수 있습니다.

### 4. **ss 또는 `nstat`를 사용하여 TCP 에러 확인**
`nstat`는 네트워크 스택에서 통계 정보를 수집할 수 있는 도구입니다.

```bash
nstat | grep -i tcp
```

이 명령어는 TCP 통계 정보를 나열하며, 전송 실패, 재전송 패킷 등 TCP 에러 관련 정보를 제공합니다.

### 5. **proc 파일 시스템에서 확인**
`/proc/net/tcp` 파일은 현재 시스템의 TCP 소켓에 대한 정보를 담고 있습니다.

```bash
cat /proc/net/snmp | grep -i tcp
```

이 명령어를 통해 TCP 관련 통계를 확인할 수 있습니다. 특히 `TCPRetransSegs`는 재전송된 패킷 수를 나타냅니다.

이 도구들을 활용하여 커널 레벨에서 TCP 에러의 원인과 상태를 진단할 수 있습니다.
