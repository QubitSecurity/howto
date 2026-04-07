#!/bin/bash

### 루트 권한 check
U=$(env | grep "^SUDO_USER=" | cut -d"=" -f2)
if [[ x$U == "x" ]];then
  echo "should get super user permition with ( sudo -i )"
  exit 1
fi

## sysadmin 계정 sudo 권한
TARGET=/etc/sudoers
CHECK=$(grep -n ^sysadmin $TARGET)
cp -f $TARGET $TARGET.bak
if [[ -n $CHECK ]];then
  awk 'NR==102{print "sysadmin        ALL=(ALL)       NOPASSWD: ALL"}104' $TARGET.bak > $TARGET
  echo $CHECK
fi
unset TARGET CHECK

## root 계정의 원격 접속 제한
TARGET=/etc/ssh/sshd_config
CHECK=$(grep -n ^PermitRootLogin $TARGET)
if [[ -n $CHECK ]];then
  TNUM=$(cut -d':' -f1 <<< $CHECK)
  TSTR=$(cut -d':' -f2 <<< $CHECK)
  if [[ $(echo $CHECK | grep -i yes$) ]];then
    sed -i "${TNUM}s/$TSTR/PermitRootLogin no/g" $TARGET
  fi
else
  echo "PermitRootLogin no" >> $TARGET
fi
unset TARGET CHECK TNUM TSTR
 
 
## 계정 잠금 임계값 설정
if [[ -z $(grep "pam_tally2.so" /etc/pam.d/password-auth-ac) ]];then
  sed -i '5 i\auth        required      pam_tally2.so deny=5 magic_root unlock_time=600;
         11 i\account     required      pam_tally2.so' /etc/pam.d/password-auth-ac
fi
if [[ -z $(grep "pam_tally2.so" /etc/pam.d/system-auth-ac) ]];then
  sed -i '5 i\auth        required      pam_tally2.so deny=5 magic_root unlock_time=600;
         11 i\account     required      pam_tally2.so' /etc/pam.d/system-auth-ac
fi
 
 
## 패스워드 복잡성 설정 - 패스워드 최소 길이 설정
TARGET=/etc/login.defs
CHECK=$(grep -n ^PASS_MIN_LEN $TARGET)
if [[ -n $CHECK ]];then
  TNUM=$(cut -d':' -f1 <<< $CHECK)
  TSTR=$(cut -d':' -f2 <<< $CHECK)
  TVELUE=$(awk '{print $2}' <<< $TSTR)
  if [ $TVELUE -lt 8 ];then
    sed -i "${TNUM}s/$TSTR/PASS_MIN_LEN\t8/g" $TARGET
  fi
else
  echo "PASS_MIN_LEN\t8" >> $TARGET
fi
 
 
## 패스워드 복잡성 설정 - 패스워드 최대 사용 기간 설정
TARGET=/etc/login.defs
CHECK=$(grep -n ^PASS_MAX_DAYS $TARGET)
if [[ -n $CHECK ]];then
  TNUM=$(cut -d':' -f1 <<< $CHECK)
  TSTR=$(cut -d':' -f2 <<< $CHECK)
  TVELUE=$(awk '{print $2}' <<< $TSTR)
  if [ $TVELUE -gt 90 ];then
     sed -i "${TNUM}s/$TSTR/PASS_MAX_DAYS\t90/g" $TARGET
  fi
else
  echo "PASS_MAX_DAYS\t90" >> $TARGET
fi
 
 
## 패스워드 복잡성 설정 - 패스워드 최소 사용 기간 설정(0 일 설정 금지)
TARGET=/etc/login.defs
CHECK=$(grep -n ^PASS_MIN_DAYS $TARGET)
if [[ -n $CHECK ]];then
  TNUM=$(cut -d':' -f1 <<< $CHECK)
  TSTR=$(cut -d':' -f2 <<< $CHECK)
  TVELUE=$(awk '{print $2}' <<< $TSTR)
  if [ $TVELUE -eq 0 ];then
     sed -i "${TNUM}s/$TSTR/PASS_MIN_DAYS\t1/g" $TARGET
  fi
else
  echo "PASS_
MIN_DAYS\t1" >> $TARGET
fi
 
## ssh - Session Timeout 설정
if [[ -z $(grep "^TMOUT=600" /etc/profile) ]];then
  echo "TMOUT=600" >> /etc/profile
fi
 
## UMASK 설정 관리
TARGET=/etc/login.defs
CHECK=$(grep -n ^UMASK $TARGET)
if [[ -n $CHECK ]];then
  TNUM=$(cut -d':' -f1 <<< $CHECK)
  TSTR=$(cut -d':' -f2 <<< $CHECK)
  TVELUE=$(awk '{print $2}' <<< $TSTR)
  if [ $TVELUE -lt 22 ];then
     sed -i "${TNUM}s/$TSTR/UMASK\t\t22/g" $TARGET
  fi
else
   echo "UMASK\t\t22" >> $TARGET
fi
 
## cron 파일 소유자 및 권한 설정 (권한 제한(only root))
echo root > /etc/cron.allow
 
 
## 패스워드 파일 보호 / /etc/passwd 파일 소유자 및 권한 설정
chmod 400 /etc/shadow
chown root:root /etc/shadow
 
 
## 로그온시 경고 메세지 제공
echo -e "\e[31;1m
 o       o   O   o   o o   o o-O-o o   o  o-o
 |       |  / \  |\  | |\  |   |   |\  | o
 o   o   o o---o | \ | | \ |   |   | \ | |  -o
  \ / \ /  |   | |  \| |  \|   |   |  \| o   |
   o   o   o   o o   o o   o o-O-o o   o  o-o
\e[32;1m
This Server useable to QUBITSEC User Only.
\e[0m" > /etc/motd
 
 
### 어드민 그룹(wheel) 현재 접속한 ID 설정
ADMINGROUP="wheel"
if [[ ! -z $U ]];then
  ACID=$U
fi

## 어드민 그룹이 없을 경우 생성한다.
if [[ ! -z $(id $ACID 2>/dev/null) ]];then
  if [[ -z $(grep ^$ADMINGROUP: /etc/group) ]];then
    groupadd -r $ADMINGROUP
  fi

## root 계정 su 제한
  chgrp $ADMINGROUP $(which su)
  chmod 4750 $(which su)

## SUID, SGID, Sticky bit 설정 파일 점검
  chgrp $ADMINGROUP $(which newgrp)
  chmod 4750 $(which newgrp) $(which unix_chkpwd)

## 불필요한 계정 제거
  ID_LIST=( adm lp sync shutdown halt news uucp operator games gopher nfsnobody squid ftp www-data list )
  for a in ${ID_LIST[@]}
    do
    if [[ ! -z $(id $a 2>/dev/null) ]];then
      userdel $a
      DELLIST="$DELLIST $a"
    fi
    done
  if [[ ! -z $DELLIST ]];then echo -e "\e[31;1m"$DELLIST" art deleted.\e[0m";fi
  unset ID_LIST DELLIST ADMINGROUP

## 홈 디렉토리의 존재 관리
  echo "아래 리스트는 계정별 홈디렉토리를 나타낸다. / 홈디렉토리가 없는 계정이 존재해서는 안된다."
  for b in $(awk -F: '!/^#/&&$6!~/^\/dev\/null$/&&$6!~/^\/$/{print $1":"$6}' /etc/passwd)
    do
    USERNAME=$(cut -d: -f1 <<< $b)
    USERHOME=$(cut -d: -f2 <<< $b)
    if [ ! -d $USERHOME ];then
      echo "$USERNAME"
    else
      if [[ -z $(ls -dal $USERHOME|grep ^d......--.) ]];then
      echo -en "\e[31;1m$USERNAME"
      ls --time-style=long-iso -dal $(readlink -f $USERHOME)|awk '{print "\t"$1"\t"$3"\t"$4"\t"$8}'
    fi;fi
    done
  echo -e "\e[0m"

## 계정이 존재하지 않는 GID 금지
  echo "아래 리스트는 그룹별 속한 아이디를 보여 준다. / 속한 아이디가 없는 그룹은 삭제해야 한다."
  for a in $(cat /etc/group|grep -v ^#)
    do
    GROUPNAME=$(cut -d: -f1 <<< "$a")
    GROUPNUM=$(cut -d: -f3 <<< "$a")
    ACCHECK=$(awk -F: '!/^#/&&$4~/^'$GROUPNUM'$/{print $1}' /etc/passwd)
    if [[ -z $ACCHECK ]];then
      if [[ $GROUPNAME == "cdrom" ]] ||  [[ $GROUPNAME == "floppy" ]] ||
         [[ $GROUPNAME == "tape" ]] ||   [[ $GROUPNAME == "dialout" ]];then
        echo -e "\e[34;1m$GROUPNAME group for default devices\e[0m" #> /dev/null
      elif [[ $GROUPNAME == "disk" ]] || [[ $GROUPNAME == "sys" ]] ||
           [[ $GROUPNAME == "mem" ]] ||  [[ $GROUPNAME == "kmem" ]] ||
           [[ $GROUPNAME == "man" ]] ||  [[ $GROUPNAME == "systemd-journal" ]] ||
           [[ $GROUPNAME == "lock" ]] || [[ $GROUPNAME == "man" ]] ||
           [[ $GROUPNAME == "input" ]];then
        echo -e "\e[34;1m$GROUPNAME group for Linux kernel\e[0m" #> /dev/null
      elif  [[ $GROUPNAME == "man" ]];then
        echo -e "\e[34;1m$GROUPNAME group for manual\e[0m" #> /dev/null
      else
        if [[ -z $(groupmems -l -g $GROUPNAME) ]];then
          if [[ -z $(find / -xdev -group $GROUPNAME) ]];then
            echo -e "\e[31;1m$GROUPNAME group is empty\e[0m"
          else echo -e "\e[34;1m$GROUPNAME group has some file and folder.\e[0m"
          fi
        else echo -e "\e[32;1m$GROUPNAME group has [ $(groupmems -l -g $GROUPNAME) ]\e[0m"
      fi;fi
    else
      echo -e "\e[32;1m$GROUPNAME group has [ "$ACCHECK" ]\e[0m"
    fi
    unset ACCHECK GROUPNUM GROUPNAME
    done
fi
