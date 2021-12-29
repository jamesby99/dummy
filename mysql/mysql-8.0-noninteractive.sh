#!/bin/bash

#------------------------------------------------------------------------------
# [ 실행전 TODO, 꼭 확인할 것 ]
# 1. 
# 2.
# 3. 
#------------------------------------------------------------------------------

if [ -z "$1" ] || [ -z "$2" ] ; then
	echo ">>>>> usage	  : mysql-8.0-noninteractive.sh <version> <root-password>"
	echo ">>>>> example	: mysql-8.0-noninteractive.sh 8.0.25 ktcloud!!"
	exit
fi

apt-get update -y
apt-get upgrade -y

#for KT Cloud D1
apt-get install apparmor -y

