ansible -i ./ansible/hosts all-chronyhosts -m command -a "sudo chronyc -a makestep"
