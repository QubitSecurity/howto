## MySQL Replication Delay Check

### 1.1 detect_check_replication_delay.sh
````
  ssh root@10.100.21.60
  vi ~/.bashrc
  source ~/.bashrc
  ssh root@10.10.21.60

  ssh-keygen -p -f ~/.ssh/id_rsa

  ssh root@10.10.21.60
  ssh root@10.10.21.62
````

````
  bash ./check_replication_delay-60.sh 
  ssh root@10.100.21.60
  ssh root@10.100.21.62
  bash ./check_replication_delay-60.sh 
  vi check_replication_delay-60.sh 
  ssh-copy-id root@10.100.21.60
  ssh-copy-id root@10.100.21.62
  ssh root@10.100.21.60
  eval "$(ssh-agent -s)"
  ssh root@10.100.21.60
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/id_rsa
  chmod 644 ~/.ssh/id_rsa.pub
  ssh root@10.100.21.60
````
