#!/usr/bin/env bash

#------------------------------------------------------------------------------
# postgresql 리파지토리 및 사이닝키 추가후 설치
#------------------------------------------------------------------------------
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
apt update -y
apt install pgpool2 postgresql-12-pgpool2 -y

