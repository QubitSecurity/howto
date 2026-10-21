#!/usr/bin/env python3
"""Real Go sender + real Go health daemon + minimal TCP->omprog TEST adapter.
NOT a substitute for actual rsyslog/HAProxy integration. Localhost only.
"""
import json, pathlib, selectors, socket, socketserver, subprocess, tempfile, threading, time, urllib.request, urllib.error
ROOT=pathlib.Path(__file__).resolve().parents[1]

def ack(p,timeout=3):
    with selectors.DefaultSelector() as sel:
        sel.register(p.stdout,selectors.EVENT_READ)
        if not sel.select(timeout):raise RuntimeError('omprog timeout')
        data=p.stdout.readline()
        if data.strip()!=b'OK':raise RuntimeError('bad omprog ack: '+repr(data))

def freeport():
    with socket.socket() as s:s.bind(('127.0.0.1',0));return s.getsockname()[1]

def main():
    exe=ROOT/'bin/plura-syslog-sender'
    with tempfile.TemporaryDirectory(prefix='plura-health-') as temp:
        td=pathlib.Path(temp);path=str(td/'health.sock');hp=freeport()
        cfg={'allowedSourceIps':['127.0.0.1'],'allowedDestinationCidrs':['127.0.0.1/32'],'allowTestLoopback':True,'debug':True,'healthProbeSourceIp':'127.0.0.1','healthAckSocket':path}
        (td/'sender.json').write_text(json.dumps(cfg))
        logs=[];procs=[]
        blocked=threading.Event();lock=threading.Lock()
        try:
            logs.append((td/'sender.log').open('wb'))
            sender=subprocess.Popen([str(exe),'-config',str(td/'sender.json')],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=logs[-1],bufsize=0);procs.append(sender);ack(sender)
            class Handler(socketserver.StreamRequestHandler):
                def handle(self):
                    self.request.settimeout(2)
                    try:
                        prefix=b''
                        while True:
                            ch=self.rfile.read(1)
                            if not ch:return
                            if ch==b' ':break
                            prefix+=ch
                            if len(prefix)>6:return
                        size=int(prefix);raw=self.rfile.read(size).decode('utf8')
                        if blocked.is_set():return
                        app=raw.split(' ',6)[3]
                        env={'app':app,'source':self.client_address[0],'raw':raw}
                        with lock:
                            sender.stdin.write((json.dumps(env)+'\n').encode());ack(sender)
                    except (OSError,ValueError,RuntimeError,IndexError):return
            class Server(socketserver.ThreadingTCPServer):
                daemon_threads=True;allow_reuse_address=True
            server=Server(('127.0.0.1',0),Handler)
            thread=threading.Thread(target=server.serve_forever,daemon=True);thread.start()
            hc={'nodeId':'test','listenAddress':f'127.0.0.1:{hp}','allowedPeerIps':['127.0.0.1'],'probeAddress':f'127.0.0.1:{server.server_address[1]}','probeSourceIp':'127.0.0.1','ackSocket':path,'drainFile':str(td/'drain'),'intervalMs':200,'timeoutMs':400,'staleMs':1200}
            (td/'health.json').write_text(json.dumps(hc));logs.append((td/'health.log').open('wb'))
            health=subprocess.Popen([str(exe),'-health','-config',str(td/'health.json')],stdout=logs[-1],stderr=logs[-1]);procs.append(health)
            opener=urllib.request.build_opener(urllib.request.ProxyHandler({}))
            def status(path='/ready'):
                try:
                    with opener.open(f'http://127.0.0.1:{hp}'+path,timeout=1) as r:return r.status
                except urllib.error.HTTPError as e:return e.code
                except OSError:return 0
            def wait(wanted):
                until=time.monotonic()+6
                while time.monotonic()<until:
                    if status()==wanted:return
                    time.sleep(.1)
                raise AssertionError(f'expected {wanted}, got {status()}')
            wait(200);print('PASS: readiness only after TCP -> omprog -> Go nonce callback (test adapter)')
            with socket.create_connection(('127.0.0.1',hp),timeout=2) as check:
                check.sendall(b'GET /ready HTTP/1.0\r\nHost: plura-gateway\r\n\r\n')
                response=check.recv(4096)
                assert response.startswith(b'HTTP/1.0 200'),response
            print('PASS: exact HAProxy HTTP/1.0 200 expectation remains compatible')

            blocked.set();wait(503)
            with socket.create_connection(server.server_address,timeout=1):pass
            assert status('/live')==200
            print('PASS: TCP listener still open but processing blocked -> readiness 503')
            blocked.clear();wait(200);print('PASS: pipeline recovery -> readiness 200')
            (td/'drain').touch();wait(503);(td/'drain').unlink();wait(200)
            print('PASS: drain marker blocks readiness and removing it restores readiness')
            sender.kill();sender.wait(timeout=3);wait(503)
            print('PASS: Go Sender process failure detected, despite TCP port remaining open')
            server.shutdown();server.server_close()
        finally:
            for p in reversed(procs):
                if p.poll() is None:
                    p.terminate()
                    try:p.wait(timeout=4)
                    except subprocess.TimeoutExpired:p.kill();p.wait(timeout=2)
            for f in logs:f.close()
        print('NOTICE: Actual rsyslog/HAProxy not used in this smoke test.')
if __name__=='__main__':main()
