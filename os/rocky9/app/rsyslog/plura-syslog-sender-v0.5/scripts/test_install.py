#!/usr/bin/env python3
"""Installer dry staging test. DESTDIR never touches the host's real /etc."""
import json, os, pathlib, subprocess, tempfile, hashlib
ROOT=pathlib.Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='plura-install-') as d:
    root=pathlib.Path(d);etc=root/'etc/plura-syslog';etc.mkdir(parents=True)
    sender=json.loads((ROOT/'conf/sender.json').read_text().replace('<HAPROXY_SOURCE_IP>','192.168.200.199'))
    health=json.loads((ROOT/'conf/health.json').read_text().replace('<HAPROXY_SOURCE_IP>','192.168.200.199'))
    sender['debug']=True
    for name,obj in [('sender.json',sender),('health.json',health)]: (etc/name).write_text(json.dumps(obj,indent=2)+'\n')
    prior={p.name:p.read_bytes() for p in etc.iterdir()}
    cfg=root/'etc/rsyslog.d';cfg.mkdir();(cfg/'30-plura-gateway.conf').write_text('# KEEP EXISTING CONFIG\n')
    env=dict(os.environ,DESTDIR=d)
    for _ in range(2):
        subprocess.run(['bash',str(ROOT/'scripts/install-sender-v05.sh')],env=env,cwd=ROOT,check=True,stdout=subprocess.DEVNULL)
    for name,content in prior.items(): assert (etc/name).read_bytes()==content, name
    assert (cfg/'30-plura-gateway.conf').read_text()=='# KEEP EXISTING CONFIG\n'
    exe=root/'usr/libexec/rsyslog/plura-syslog-sender'
    assert subprocess.check_output([str(exe),'-version']).strip()==b'0.5.0'
    before=hashlib.sha256(exe.read_bytes()).digest()
    health['probeSourceIp']='192.168.200.201';(etc/'health.json').write_text(json.dumps(health))
    p=subprocess.run(['bash',str(ROOT/'scripts/install-sender-v05.sh')],env=env,cwd=ROOT,capture_output=True)
    assert p.returncode!=0 and hashlib.sha256(exe.read_bytes()).digest()==before
    assert list((root/'var/backups/plura-syslog').iterdir())
print('PASS: install/upgrade preserves configs and rsyslog; backup + atomic executable replacement; invalid config aborts before replacement')
