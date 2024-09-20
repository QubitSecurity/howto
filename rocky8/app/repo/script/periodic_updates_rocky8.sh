#!/bin/bash

reposync -p /var/www/repos/rocky/8/x86_64/os/ --newest-only --repo=baseos --download-metadata
sleep 5

reposync -p /var/www/repos/rocky/8/x86_64/os/ --newest-only --repo=appstream --download-metadata
sleep 5

reposync -p /var/www/repos/rocky/8/x86_64/os/ --newest-only --repo=extras --download-metadata
sleep 5

createrepo --update /var/www/repos/rocky/8/x86_64/os/appstream/
sleep 5

createrepo --update /var/www/repos/rocky/8/x86_64/os/baseos/
sleep 5

createrepo --update /var/www/repos/rocky/8/x86_64/os/extras/
sleep 5

reposync -p /var/www/repos/rocky/epel/8/Everything/x86_64/ --newest-only --repo=epel --download-metadata
sleep 5

createrepo --update /var/www/repos/rocky/epel/8/Everything/x86_64/
