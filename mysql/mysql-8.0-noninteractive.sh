#!/bin/bash

#------------------------------------------------------------------------------
# [ 실행전 TODO, 꼭 확인할 것 ]
# 1. root 계정에서 실행 할 것
# 2. 
# 3. 
#------------------------------------------------------------------------------

if [ -z "$1" ] || [ -z "$2" ] ; then
	echo ">>>>> usage	: mysql-8.0-noninteractive.sh <account> <root-password>"
	echo ">>>>> example	: mysql-8.0-noninteractive.sh dbaas-root ktcloudpw!!"
	exit
fi

_ACCOUNT_=$1
_PASSWORD_=$2

# 안되어 있는 경우 대비
apt-get update -y
apt-get upgrade -y

# for KT Cloud D1
apt-get install apparmor -y

# mysql repository key 추가
apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 5072E1F5

# mysql respository 추가
echo 'deb http://repo.mysql.com/apt/ubuntu/ bionic mysql-8.0' > /etc/apt/sources.list.d/mysql.list

# noninteractive 설정(root 비밀번호 자동 입력) 및 자동 설치
debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password ${_PASSWORD_}"
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password ${_PASSWORD_}"
DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-server

sleep 5

# 외부 접속 가능한 신규 계정
mysql -uroot --password=${_PASSWORD_} -e "CREATE USER '${_ACCOUNT_}'@'%' IDENTIFIED BY '${_PASSWORD_}';"

# 권한 부여
mysql -uroot --password=${_PASSWORD_} -e "GRANT ALL PRIVILEGES ON *.* TO '${_ACCOUNT_}'@'%' WITH GRANT OPTION;"

# DB 반영
mysql -uroot --password=${_PASSWORD_} -e "FLUSH PRIVILEGES;"





