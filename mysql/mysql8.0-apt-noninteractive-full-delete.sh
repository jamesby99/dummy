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

# 설정,데이터포함 mysql-server 삭제
apt-get remove --purge mysql-server -y

# mysql-server 의존성 파일 모두 삭제
apt-get autoremove -y

apt-get autoclean
