#!/bin/bash

_LOG_FILE=xtrabackup-install-$(date +"%Y%m%d-%H%M%S").log

echo "$(date +"%Y-%m %d-%H:%M:%S") xtrabackup 설치 시작 --------------------------------------------------------------------------" >> $_LOG_FILE

echo "$(date +"%Y-%m %d-%H:%M:%S") xtrabackup repository 설정 시작 ---------------------------------------------------------------" >> $_LOG_FILE
wget https://repo.percona.com/apt/percona-release_latest.$( lsb_release -sc )_all.deb >> $_LOG_FILE 2>&1
dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb >> $_LOG_FILE 2>&1
percona-release setup ps80 >> $_LOG_FILE 2>&1
apt-get update -y >> $_LOG_FILE 2>&1

echo "$(date +"%Y-%m %d-%H:%M:%S") xtrabackup 설치 시작 --------------------------------------------------------------------------" >> $_LOG_FILE
apt-get install percona-xtrabackup-80 qpress  -y >> $_LOG_FILE 2>&1

echo "$(date +"%Y-%m %d-%H:%M:%S") xtrabackup 설치 종료 --------------------------------------------------------------------------" >> $_LOG_FILE


