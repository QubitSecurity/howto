#!/usr/bin/env python3
"""Verify the no-extra-package Bash MSA test client's TCP framing on localhost."""
import os, pathlib, socket, subprocess, threading
ROOT=pathlib.Path(__file__).resolve().parents[1]
with socket.socket() as listener:
    listener.bind(('127.0.0.1',0));listener.listen(1);listener.settimeout(4)
    result=[]
    def recv():
        c,_=listener.accept()
        with c:
            c.settimeout(4);data=b''
            while True:
                part=c.recv(16384)
                if not part:break
                data+=part
            result.append(data)
    th=threading.Thread(target=recv,daemon=True);th.start()
    env=dict(os.environ,GATEWAY_PORT=str(listener.getsockname()[1]))
    subprocess.run(['bash',str(ROOT/'scripts/syslog-test.sh'),'tcp','HA 한글 TCP -> UDP','127.0.0.1','172.16.12.212','514','udp'],env=env,check=True)
    th.join(5);assert result
    n,raw=result[0].split(b' ',1)
    assert int(n)==len(raw)
    assert b'proto="udp"' in raw and b'framing="none"' in raw
    assert raw.decode().endswith('HA 한글 TCP -> UDP')
    print('PASS: Bash TCP ingress framing uses UTF-8 byte length; customer UDP choice is independent')
