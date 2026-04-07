#!/bin/bash

reposync -p /var/www/repos/centos/7/os/x86_64/ --repo=base --download-metadata
sleep 5

reposync -p /var/www/repos/centos/7/updates/x86_64/ --repo=updates --download-metadata
sleep 5

reposync -p /var/www/repos/centos/7/extras/x86_64/ --repo=extras --download-metadata
sleep 5

reposync -p /var/www/repos/centos/7/centosplus/x86_64/ --repo=centosplus --download-metadata
sleep 5

createrepo --update /var/www/repos/centos/7/os/x86_64/
sleep 5

createrepo --update /var/www/repos/centos/7/updates/x86_64/
sleep 5

createrepo --update /var/www/repos/centos/7/extras/x86_64/
sleep 5

createrepo --update /var/www/repos/centos/7/centosplus/x86_64/
sleep 5

reposync -p /var/www/repos/ --repo=epel --download-metadata
sleep 5

createrepo --update /var/www/repos/epel/
