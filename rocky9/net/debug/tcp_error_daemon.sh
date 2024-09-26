# cat tcp_error_daemon.sh 
#!/bin/bash

#   
LOGFILE="/root/tcpdump_timeouts.log"

# TCPDUMP  TCP 443     ACK
#tcpdump -i eth1 'tcp port 443' -nnvvv 2>&1 | grep -E 'tcp retransmission|dup ack' > $LOGFILE &
tcpdump -i eth1 '(tcp port 443 or tcp port 80)' -nnvvv 2>&1 | grep -E 'tcp retransmission|dup ack' > $LOGFILE &

#echo "Starting tcpdump..." >> /tmp/tcp_error_daemon_debug.log
#tcpdump -i enp7s0 'tcp port 443' -nnvvv 2>&1 | grep -E 'tcp retransmission|dup ack' > $LOGFILE &

# tcpdump  ID 
TCPDUMP_PID=$!

#    
monitor_timeouts() {
    LASTSIZE=0
    while true; do
        CURSIZE=$(stat -c%s "$LOGFILE")
        if [[ $CURSIZE -ne $LASTSIZE ]]; then
            echo "  : $(date)"
            tail -n 10 "$LOGFILE"
            LASTSIZE=$CURSIZE
        fi
        sleep 5  # 5  
    done
}

#  
monitor_timeouts &

#   ID 
MONITOR_PID=$!

#   tcpdump  
trap "kill $TCPDUMP_PID $MONITOR_PID; exit" SIGINT SIGTERM

# tcpdump  
wait $TCPDUMP_PID
