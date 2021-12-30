#!/bin/bash

#------------------------------------------------------------------------------
# [ 실행전 TODO, 꼭 확인할 것 ]
#
# 1. root 계정에서 실행 할 것
# 2. https://artfiles.org/mysql.com/Downloads/MySQL-8.0/ 에서 희망 버전 링크 확인 할것
# 3. 
#------------------------------------------------------------------------------

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] ; then
	echo ">>>>> usage	: mysql-8.0-dpkg-noninteractive-install.sh <account> <root-password> <version>"
	echo ">>>>> example	: mysql-8.0-dpkg-noninteractive-install.sh dbaas-root ktcloudpw!! 8.0.27"
	exit
fi

_ACCOUNT_=$1
_PASSWORD_=$2
_VERSION=$3

# 안되어 있는 경우 대비
apt-get update -y
apt-get upgrade -y

# for KT Cloud D1
apt-get install apparmor -y

# 사전 의존성 설치
apt-get install libaio1 libmecab2 apparmor -y

# 작업 공간으로 이동
mkdir -p /tmp/mysql-${_VERSION} && cd /tmp/mysql-${_VERSION}

# bundle.tar 다운로도 
_BUNDLE_TAR=mysql-server_${_VERSION}-1ubuntu18.04_amd64.deb-bundle.tar


# 압축해제
if [ ! -e ${_BUNDLE_TAR} ] ; then
	wget https://artfiles.org/mysql.com/Downloads/MySQL-8.0/${_BUNDLE_TAR}
fi
tar -xvf ./${_BUNDLE_TAR}

# noninteractive 설정(root 비밀번호 자동 입력) 및 자동 설치
debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password ${_PASSWORD_}"
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password ${_PASSWORD_}"
debconf-set-selections <<< "mysql-community-server mysql-server/default-auth-override select Use Strong Password Encryption (RECOMMENDED)"

DEBIAN_FRONTEND=noninteractive

# 설치
dpkg -i mysql-{common,community-client-plugins,community-client-core,community-client,client,community-server-core,community-server,server}_*ubuntu18.04_amd64.deb

sleep 5

# 외부 접속 가능한 신규 계정
mysql -uroot --password=${_PASSWORD_} -e "CREATE USER '${_ACCOUNT_}'@'%' IDENTIFIED BY '${_PASSWORD_}';"

# 권한 부여
mysql -uroot --password=${_PASSWORD_} -e "GRANT ALL PRIVILEGES ON *.* TO '${_ACCOUNT_}'@'%' WITH GRANT OPTION;"

# DB 반영
mysql -uroot --password=${_PASSWORD_} -e "FLUSH PRIVILEGES;"

