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

# OS 사용자 생성 - app계정, replica
useradd -s /bin/bash -d /home/$__USER__ -m $__USER__
echo "$__USER__ ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$__USER__
useradd -s /bin/bash -d /home/replica -m replica

systemctl stop postgresql
# db 저장소 변경 - 사전 /postgresql에 disk가 마운트 되어 있어야 한다.
cp -rf /var/lib/postgresql/12/main/* /postgresql
chown -R postgres:postgres /postgresql
sed -i.bak -r "s#data_directory = '/var/lib/postgresql/12/main'#data_directory = '/postgresql'#g" /etc/postgresql/12/main/postgresql.conf

systemctl start postgresql

# 수작업으로 해야 한다.
echo 'DB 사용자 및 테이블 생성은 다음 절차를 따른다. : 참고 OS와 DB사용자를 일치시켜라!!!'
echo 'su - postgres'
echo 'createuser __USER__'
echo 'createuser replica --replication'
echo 'psql -c "alter user __USER__ with password 'imdb21**';"'
echo 'psql -c "alter user replica with password 'imdb21**';"'
echo 'psql -c "select usename from pg_user;"'
echo 'createdb db_projection -O __USER__'
echo 'createdb db_order -O __USER__'
echo 'createdb db_configuration -O __USER__'
echo 'createdb db_backupmgt -O __USER__'
echo 'createdb db_servermgt -O __USER__'
echo 'psql -l'

echo 'sudo -u postgres psql -c "show data_directory;"' #변경 디렉토리 확인

