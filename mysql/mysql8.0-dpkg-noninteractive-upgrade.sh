#!/bin/bash

#------------------------------------------------------------------------------
# [ 실행전 TODO, 꼭 확인할 것 ]
#
# 1. root 계정에서 실행 할 것
# 2. https://artfiles.org/mysql.com/Downloads/MySQL-8.0/ 에서 희망 버전 링크 확인 할것
# 3. 
#------------------------------------------------------------------------------

if [ -z "$1" ] ; then
	echo ">>>>> usage	: mysql8.0-dpkg-noninteractive-upgrade.sh <version>"
	echo ">>>>> example	: mysql8.0-dpkg-noninteractive-upgrade.sh 8.0.27"
	exit
fi

_VERSION=$1

# 사전 점검 12가지 체크
# DB full backup
# my.cnf backup

# apt, dpkg lock이 있다면 제거
killall apt apt-get
rm /var/lib/apt/lists/lock
rm /var/cache/apt/archives/lock
rm /var/lib/dpkg/lock

echo "$(date +"%Y-%m-%d %H:%M:%S") apt update 시작" >> /root/install.log
apt-get update -y

echo "$(date +"%Y-%m-%d %H:%M:%S") apt upgrade 시작" >> /root/install.log
apt-get upgrade -y

echo "$(date +"%Y-%m-%d %H:%M:%S") mysql stop 시작" >> /root/install.log
systemctl stop mysql


echo "$(date +"%Y-%m-%d %H:%M:%S") mysql 기존 패키지 삭제 시작" >> /root/install.log
# noninteractive 설정 - data-dir는 그대로
debconf-set-selections <<< "mysql-community-server mysql-community-server/remove-data-dir boolean false"
DEBIAN_FRONTEND=noninteractive

# DB엔진 완전삭제 수행
# 버전마다 패키지 구성이 다르므로 이를 확인해 주어야 한다. 
# 8.0.24에 mysql-community-client-plugins 존재 확인
# 8.0.19에 mysql-community-client-plugins 미존재 확인
dpkg -r mysql-common mysql-community-client-plugins mysql-community-client-core mysql-community-client mysql-client mysql-community-server-core mysql-community-server mysql-server


echo "$(date +"%Y-%m-%d %H:%M:%S") 사전 의존성 설치 시작" >> /root/install.log
# for KT Cloud D1
apt-get install apparmor -y
# 사전 의존성 설치
apt-get install libaio1 libmecab2 apparmor -y



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
#debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password ${_PASSWORD_}"
#debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password ${_PASSWORD_}"
debconf-set-selections <<< "mysql-community-server  mysql-community-server/data-dir note"
#debconf-set-selections <<< "mysql-community-server mysql-server/default-auth-override select Use Strong Password Encryption (RECOMMENDED)"
DEBIAN_FRONTEND=noninteractive

# 설치시 my.cnf.orgin 를 복사해 놓고, 업그레이드시 현재 my.cnf를 my.cnf.orgin으로 교체(my.cnf.current)한다.

# 설치
echo "$(date +"%Y-%m-%d %H:%M:%S") mysql package 설치 시작" >> /root/install.log
dpkg -i mysql-{common,community-client-plugins,community-client-core,community-client,client,community-server-core,community-server,server}_*ubuntu18.04_amd64.deb


