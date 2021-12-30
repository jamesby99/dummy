#!/bin/bash

#------------------------------------------------------------------------------
# [ 실행전 TODO, 꼭 확인할 것 ]
#
# 1. root 계정에서 실행 할 것
# 2. 정말 이전 버전의 설정, 데이타, 로그 등을 모두 삭제할 것인?
# 3. 
#------------------------------------------------------------------------------


# stop mysql
systemctl stop mysql

# noninteractive 설정 - 전체 완전 삭제
debconf-set-selections <<< "mysql-community-server mysql-community-server/remove-data-dir boolean true"
DEBIAN_FRONTEND=noninteractive

# 완전삭제 수행
dpkg -P mysql-common mysql-community-client-plugins mysql-community-client-core mysql-community-client mysql-client mysql-community-server-core mysql-community-server mysql-server
