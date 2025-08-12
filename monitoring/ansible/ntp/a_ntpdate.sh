ansible -i ./ansible/hosts all-ntphosts -m command -a "sudo ntpdate 10.100.20.248"
