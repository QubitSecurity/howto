이 스크립트는 TCP 포트 443(HTTPS)와 80(HTTP)에서 재전송(`tcp retransmission`) 및 중복 ACK(`dup ack`)을 모니터링하여 네트워크 타임아웃과 관련된 문제를 감지하고 로그로 기록하는 기능을 수행합니다. 

### 코드 설명

1. **로그 파일 경로 설정:**
   ```bash
   LOGFILE="/root/tcpdump_timeouts.log"
   ```
   - 로그 파일을 저장할 경로를 `/root/tcpdump_timeouts.log`로 설정합니다.

2. **TCPDUMP 실행:**
   ```bash
   tcpdump -i eth1 '(tcp port 443 or tcp port 80)' -nnvvv 2>&1 | grep -E 'tcp retransmission|dup ack' > $LOGFILE &
   ```
   - `tcpdump` 명령어를 사용하여 `eth1` 네트워크 인터페이스에서 포트 443(HTTPS)과 포트 80(HTTP) 트래픽을 모니터링합니다.
   - `-nnvvv` 옵션은 호스트 이름 및 포트 번호를 숫자로 표시하고, 패킷의 자세한 정보를 출력합니다.
   - `grep -E 'tcp retransmission|dup ack'`로 `tcp retransmission` 및 `dup ack` 패턴을 가진 패킷을 필터링하여 `$LOGFILE`에 기록합니다.
   - `&`는 이 명령을 백그라운드에서 실행합니다.
   - `TCPDUMP_PID=$!`는 백그라운드에서 실행된 `tcpdump` 명령의 프로세스 ID를 저장합니다.

3. **로그 변경 모니터링 함수:**
   ```bash
   monitor_timeouts() {
       LASTSIZE=0
       while true; do
           CURSIZE=$(stat -c%s "$LOGFILE")
           if [[ $CURSIZE -ne $LASTSIZE ]]; then
               echo "변경 감지: $(date)"
               tail -n 10 "$LOGFILE"
               LASTSIZE=$CURSIZE
           fi
           sleep 5  # 5초마다 파일 크기 확인
       done
   }
   ```
   - `monitor_timeouts` 함수는 로그 파일의 크기를 주기적으로 검사합니다.
   - `LASTSIZE`는 이전에 저장된 로그 파일의 크기를 추적합니다.
   - `CURSIZE=$(stat -c%s "$LOGFILE")`는 현재 로그 파일의 크기를 가져옵니다.
   - 만약 로그 파일의 크기가 이전과 다르다면(새로운 로그가 추가되었다면), 현재 시간을 출력하고 로그 파일의 마지막 10줄을 출력합니다.
   - `sleep 5`는 5초마다 파일 크기를 확인하도록 설정합니다.

4. **모니터링 함수 실행:**
   ```bash
   monitor_timeouts &
   ```
   - `monitor_timeouts` 함수를 백그라운드에서 실행합니다.
   - `MONITOR_PID=$!`는 백그라운드에서 실행된 이 함수의 프로세스 ID를 저장합니다.

5. **스크립트 종료 처리:**
   ```bash
   trap "kill $TCPDUMP_PID $MONITOR_PID; exit" SIGINT SIGTERM
   ```
   - 스크립트가 종료될 때(`SIGINT`나 `SIGTERM` 시그널 수신 시), `tcpdump`와 모니터링 함수 모두를 종료하기 위해 `kill $TCPDUMP_PID $MONITOR_PID`를 수행합니다.

6. **tcpdump 프로세스 대기:**
   ```bash
   wait $TCPDUMP_PID
   ```
   - `tcpdump` 프로세스가 종료될 때까지 스크립트가 대기합니다.

이 스크립트는 백그라운드에서 `tcpdump`를 실행하여 포트 443과 80에서 발생하는 재전송 및 중복 ACK를 모니터링하고, 해당 로그를 주기적으로 확인하여 변경된 내용이 있으면 출력합니다.
