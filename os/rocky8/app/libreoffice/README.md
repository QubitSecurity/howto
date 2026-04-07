# LibreOffice

## 1. Basic

### 1.1 Uninstall

    yum remove libreoffice*

### 1.2 download

````
wget https://downloadarchive.documentfoundation.org/libreoffice/old/7.6.6.3/rpm/x86_64/LibreOffice_7.6.6.3_Linux_x86-64_rpm.tar.gz

wget https://downloadarchive.documentfoundation.org/libreoffice/old/5.4.7.2/rpm/x86_64/LibreOffice_5.4.7.2_Linux_x86-64_rpm.tar.gz
````

### 1.3 Install

````
cd /home/sysadmin/sourcedir/LibreOffice_7.6.6.3_Linux_x86-64_rpm/RPMS

yum localinstall *.rpm

````

### 1.4 make symbolic link

````
rm /usr/bin/libreoffice

ln -s /opt/libreoffice7.6/program/soffice /usr/bin/libreoffice
````

### 1.5 check version

    libreoffice --version
