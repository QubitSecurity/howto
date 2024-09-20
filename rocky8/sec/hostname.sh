#!/bin/bash

sed -i "1s/\$/ $HOSTNAME/" /etc/hosts
cat /etc/hosts
