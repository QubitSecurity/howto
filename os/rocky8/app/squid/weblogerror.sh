chown squid.root /var/log/plura/weblog.log
sleep 1

touch /var/log/plura/weblog.log
sleep 1

chown squid.root /var/log/plura/weblog.log
sleep 1

chmod -R 766 /var/log/plura/weblog.log
sleep 1

chcon -t squid_log_t /var/log/plura/weblog.log
sleep 1

systemctl restart squid
sleep 1

systemctl status squid
sleep 1
