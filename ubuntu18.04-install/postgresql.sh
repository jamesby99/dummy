#!/usr/bin/env bash

if [ -z "$1" ]; then
	echo ">>>>> usage	: postgresql.sh <db 계정>"
	echo ">>>>> example	: postgresql.sh unbuntu"
	exit
fi

__USER__=$1


# postgresql 리포지토리 및 사이닝키 추가 ------------------------------------------------
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
apt update -y


# postgresql 12 설치  -----------------------------------------------------------------
apt install postgresql-12 -y


# 외부접속 IP 설정 - 접근제한 없이 설정 ------------------------------------------------
sed -i.bak -r "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/12/main/postgresql.conf
# [변경전] 127.0.0.1:5432          0.0.0.0:*               LISTEN      24517/postgres
# [변경후] 0.0.0.0:5432            0.0.0.0:*               LISTEN      26412/postgres
echo "host    all             all             0.0.0.0/0               md5" >> /etc/postgresql/12/main/pg_hba.conf

su - postgres

systemctl restart postgresql

