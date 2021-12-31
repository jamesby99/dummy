#!/bin/bash

#------------------------------------------------------------------------------
# [ 실행전 TODO, 꼭 확인할 것 ]
#
# 1. root 계정에서 실행 할 것
# 2. 정말 이전 버전의 설정, 데이타, 로그 등을 모두 삭제할 것인가??
# 3. 
#------------------------------------------------------------------------------


# stop mysql
systemctl stop mysql

# noninteractive 모든 데이터, 설정 전체 삭제
debconf-set-selections <<< "mysql-community-server mysql-community-server/remove-data-dir boolean true"
DEBIAN_FRONTEND=noninteractive

# 설정,데이터포함 기존 설치된 것 모두 삭제
apt-get remove --purge mysql-community-client-plugins mysql-community-client-core mysql-community-client mysql-client mysql-server mysql-community-server-core mysql-community-server mysql-common mysql-apt-config -y

apt-get autoremove -y

apt-get autoclean
