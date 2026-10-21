#!/usr/bin/env python3
"""Real omprog Go binary + localhost UDP/TCP receivers; no external network."""
import json, pathlib, selectors, socket, subprocess, tempfile
ROOT = pathlib.Path(__file__).resolve().parents[1]

def ack(p):
    with selectors.DefaultSelector() as s:
        s.register(p.stdout, selectors.EVENT_READ)
        if not s.select(5): raise RuntimeError("ack timeout")
        result=p.stdout.readline().strip()
    if not result:raise RuntimeError(f"sender stopped: {p.poll()}")
    return result

def main():
    exe=ROOT/'bin/plura-syslog-sender'
    if not exe.exists():raise SystemExit('run bash scripts/build.sh first')
    with tempfile.TemporaryDirectory() as td, socket.socket(socket.AF_INET,socket.SOCK_DGRAM) as udp, socket.socket(socket.AF_INET,socket.SOCK_STREAM) as tcp:
        udp.bind(('127.0.0.1',0));udp.settimeout(5);tcp.bind(('127.0.0.1',0));tcp.listen(1);tcp.settimeout(5)
        cfg={'allowedSourceIps':['127.0.0.1'],'allowedDestinationCidrs':['127.0.0.1/32'], 'allowTestLoopback':True, 'debug':True}
        path=pathlib.Path(td)/'cfg.json';path.write_text(json.dumps(cfg))
        logfile=pathlib.Path(td)/'sender.log'
        with logfile.open('wb') as lg:
            p=subprocess.Popen([str(exe),'-config',str(path)],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=lg,bufsize=0)
            try:
                assert ack(p)==b'OK'
                print('PASS: omprog startup ack')
                def send(protocol, port, frame, msg, extra=""):
                    extra = (" " + extra) if extra else ""
                    raw=f'<134>1 2026-10-21T12:00:00Z msa plura-relay - - [pluraRelay@32473 dst="127.0.0.1" port="{port}" proto="{protocol}" framing="{frame}"{extra}] {msg}'
                    env={'app':'plura-relay','source':'127.0.0.1','raw':raw}
                    p.stdin.write((json.dumps(env,ensure_ascii=False)+'\n').encode())
                    assert ack(p)==b'OK'
                    return raw
                send('udp',udp.getsockname()[1],'none','UTF8 한글 test')
                data,_=udp.recvfrom(10000)
                assert b'pluraRelay@32473' not in data and 'UTF8 한글 test' in data.decode()
                print('PASS: UDP relay + routing SD stripped')
                send('tcp',tcp.getsockname()[1],'octet-counting','TCP UTF8 한글 test')
                conn,_=tcp.accept()
                with conn:
                    conn.settimeout(5);frame=conn.recv(10000)
                    size, payload=frame.split(b' ',1)
                    need=int(size)
                    while len(payload)<need:payload+=conn.recv(10000)
                    assert len(payload)==need and b'pluraRelay@32473' not in payload and 'TCP UTF8 한글 test' in payload.decode()
                print('PASS: TCP octet framing with UTF8 byte count')
                send('udp',udp.getsockname()[1],'none','legacy test', 'format="rfc3164"')
                data,_=udp.recvfrom(10000)
                assert data==b'<134>Oct 21 21:00:00 msa plura: legacy test'
                print('PASS: RFC3164 output via real UDP receiver')
                cef=r'CEF:0|QubitSecurity|PLURA-XDR|0.5|TEST|Relay test|5|src=203.0.113.10 msg=a\=b'
                send('udp',udp.getsockname()[1],'none',cef,'format="cef"')
                data,_=udp.recvfrom(10000)
                assert data.decode()=='<134>Oct 21 21:00:00 msa '+cef
                assert b'plura-relay:' not in data and b'pluraRelay@32473' not in data
                print('PASS: CEF + RFC3164 header; body escaping preserved')
                send('udp',udp.getsockname()[1],'none',cef,'format="cef" header="rfc5424"')
                data,_=udp.recvfrom(10000)
                assert data.decode()=='<134>1 2026-10-21T12:00:00Z msa plura-relay - - - '+cef
                print('PASS: CEF + RFC5424 header')

                bad={'app':'plura-relay','source':'127.0.0.1','raw':f'<134>1 2026-10-21T12:00:00Z msa plura-relay - - [pluraRelay@32473 dst="169.254.169.254" port="80" proto="tcp"] secret-not-in-logs'}
                p.stdin.write((json.dumps(bad)+'\n').encode());assert ack(p)==b'OK'
                p.stdin.close();assert p.wait(timeout=5)==0
            finally:
                if p.poll() is None:p.kill();p.wait(timeout=5)
        logs=logfile.read_text()
        assert 'secret-not-in-logs' not in logs and '"msg":"dropped"' in logs
        print('PASS: disallowed destination drop, no message contents in diagnostics')
if __name__=='__main__':main()
