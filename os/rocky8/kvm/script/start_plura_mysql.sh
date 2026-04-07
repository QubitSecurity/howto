#!/usr/bin/env bash

#mysql-maindb
virsh start 010240-mysql

#mysql-statsdb
virsh start 010241-mysql

#mysql-infradb
virsh start 010242-mysql

#mysql-maindb-s
virsh start 010243-mysql

#mysql-statsdb-s
virsh start 010244-mysql

#mysql-detectdb
virsh start 010245-mysql

#mysql-detectdb-s
virsh start 010246-mysql
