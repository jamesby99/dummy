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


lsof /var/lib/dpkg/lock
# unattended-upgrades 비활성화
sed -i.bak -r "s/1/0/g" /etc/apt/apt.conf.d/20auto-upgrades
__PID__=$(for pid in $(ls /proc | egrep [0-9]+); do sudo ls -l /proc/$pid/fd 2>/dev/null | grep /var/lib/dpkg/lock && echo $pid; done | tail -n 1)
if [ -n "$__PID__" ]; then
	echo "죽이기...: " + $__PID__
  	kill -9 $__PID__
fi

# apt, dpkg lock이 있다면 제거
killall apt apt-get
rm /var/lib/apt/lists/lock
rm /var/cache/apt/archives/lock
rm /var/lib/dpkg/lock

echo "$(date +"%Y-%m-%d %H:%M:%S") apt update 시작" >> /root/install.log
apt-get update -y

# 개발용에서는 해제, 상용에서는 선택
apt-get upgrade -y

echo "$(date +"%Y-%m-%d %H:%M:%S") 사전 의존성 설치 시작" >> /root/install.log
# for KT Cloud D1
apt-get install apparmor -y
# 사전 의존성 설치
apt-get install libaio1 libmecab2 -y
# 데비안 패키지 설치
apt-get install debconf-utils -y

# 작업 공간
mkdir -p /tmp/mysql-${_VERSION}
cd /tmp/mysql-${_VERSION}

# bundle.tar 다운로도 
_BUNDLE_TAR=mysql-server_${_VERSION}-1ubuntu18.04_amd64.deb-bundle.tar


echo "$(date +"%Y-%m-%d %H:%M:%S") deb-bundle.tar 다운로드 시작" >> /root/install.log
if [ ! -e ${_BUNDLE_TAR} ] ; then
	wget https://downloads.mysql.com/archives/get/p/23/file/${_BUNDLE_TAR}
fi

echo "$(date +"%Y-%m-%d %H:%M:%S") deb-bundle.tar 압축 해제 시작" >> /root/install.log
tar -xvf /tmp/mysql-${_VERSION}/${_BUNDLE_TAR}


# noninteractive 설정(root 비밀번호 자동 입력) 및 자동 설치
debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password ${_PASSWORD_}"
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password ${_PASSWORD_}"
debconf-set-selections <<< "mysql-community-server mysql-server/default-auth-override select Use Strong Password Encryption (RECOMMENDED)"
DEBIAN_FRONTEND=noninteractive

lsof /var/lib/dpkg/lock

# 설치
echo "$(date +"%Y-%m-%d %H:%M:%S") mysql package 설치 시작" >> /root/install.log
dpkg -i mysql-{common,community-client-plugins,community-client-core,community-client,client,community-server-core,community-server,server}_*ubuntu18.04_amd64.deb

sleep 5

echo "$(date +"%Y-%m-%d %H:%M:%S") mysql 설정 시작" >> /root/install.log
# 외부 접속 가능한 신규 계정
mysql -uroot --password=${_PASSWORD_} -e "CREATE USER '${_ACCOUNT_}'@'%' IDENTIFIED BY '${_PASSWORD_}';"

# 권한 부여
mysql -uroot --password=${_PASSWORD_} -e "GRANT ALL PRIVILEGES ON *.* TO '${_ACCOUNT_}'@'%' WITH GRANT OPTION;"

# DB 반영
mysql -uroot --password=${_PASSWORD_} -e "FLUSH PRIVILEGES;"

# unattended-upgrades 활성화
sed -i.bak -r "s/0/1/g" /etc/apt/apt.conf.d/20auto-upgrades
