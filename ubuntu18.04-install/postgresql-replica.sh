#!/usr/bin/env bash

if [ -z "$1" ]; then
	echo ">>>>> usage	: postgresql-replica.sh <db 계정>"
	echo ">>>>> example	: postgresql-replica.sh unbuntu"
	exit
fi

__USER__=$1

# OS 사용자 생성 - app계정, replica
useradd -s /bin/bash -d /home/$__USER__ -m $__USER__
echo "$__USER__ ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$__USER__
useradd -s /bin/bash -d /home/replica -m replica


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

echo "# 여기서부터는 커스텀마이징 설정입니다." >> /etc/postgresql/12/main/pg_hba.conf
echo "host    all             all             0.0.0.0/0               md5" >> /etc/postgresql/12/main/pg_hba.conf


# 튜닝 --------------------------------------------------------------------------------
# 메모리 2GB 기준 값으로 설정되어 있음

# [shared_buffers] 총메모리의 25% 수준: 2GB는 512MB
sed -i.bak -r "s/shared_buffers = 128MB/shared_buffers = 256MB/g" /etc/postgresql/12/main/postgresql.conf

# [effective_cache_size] 총메모리의 50% 수준: 2GB는 1GB
sed -i.bak -r "s/#effective_cache_size = 4GB/effective_cache_size = 768MB/g" /etc/postgresql/12/main/postgresql.conf

# [maintenance_work_mem] 총메모리GB x 50MB = 2GB x 50MB = 100MB
sed -i.bak -r "s/#maintenance_work_mem = 64MB/maintenance_work_mem = 64MB/g" /etc/postgresql/12/main/postgresql.conf

# [checkpoint_completion_target]
sed -i.bak -r "s/#checkpoint_completion_target = 0.5/checkpoint_completion_target = 0.9/g" /etc/postgresql/12/main/postgresql.conf

# [wal_buffers] shared_buffers의 1/32 수준이나, -1로 설정하면 shared_buffers에 따라 자동 조정
sed -i.bak -r "s/#wal_buffers = -1/wal_buffers = 7864kB/g" /etc/postgresql/12/main/postgresql.conf

# [default_statistics_target]
sed -i.bak -r "s/#default_statistics_target = 100/default_statistics_target = 100/g" /etc/postgresql/12/main/postgresql.conf

# [random_page_cost] HDD or SSD에 따라 값이 달라짐
sed -i.bak -r "s/#random_page_cost = 4.0/random_page_cost = 4.0/g" /etc/postgresql/12/main/postgresql.conf

# [effective_io_concurrency] HDD or SSD에 따라 값이 달라짐
sed -i.bak -r "s/#effective_io_concurrency = 1/effective_io_concurrency = 2/g" /etc/postgresql/12/main/postgresql.conf

# [work_mem]
sed -i.bak -r "s/#work_mem = 4MB/work_mem = 1310kB/g" /etc/postgresql/12/main/postgresql.conf

# [min_wal_size]
sed -i.bak -r "s/min_wal_size = 80MB/min_wal_size = 1GB/g" /etc/postgresql/12/main/postgresql.conf

# [max_wal_size]
sed -i.bak -r "s/max_wal_size = 1GB/max_wal_size = 4GB/g" /etc/postgresql/12/main/postgresql.conf
#--------------------------------------------------------------------------------------

# db 저장소 변경 - 사전 /postgresql에 disk가 마운트 되어 있어야 한다. -----------------
systemctl stop postgresql
cp -rf /var/lib/postgresql/12/main /postgresql
chown -R postgres:postgres /postgresql
systemctl start postgresql
systemctl stop postgresql
# -------------------------------------------------------------------------------------

echo '아래 작업은 수작업으로 진행합니다.'
echo 'su - postgres'
echo 'psql -c "show data_directory;"' #변경 디렉토리 확인
echo 'pg_basebackup -R -h <master-ip> -U replica -D /var/lib/postgresql/12/main -P'
echo 'exit'
echo 'vi /etc/postgresql/12/main/postgresql.conf'
echo 'hot_standby = on'
echo 'vi /var/lib/postgresql/12/main/postgresql.auto.conf'
echo '# add [application_name] to auto generated auth file (any name you like, like hostname and so on)'
echo "# primary_conninfo = 'user=rep_user password=password host=www.srv.world port=5432 sslmode=prefer sslcompression=0 gssencmode=prefer krbsrvname=postgres target_session_attrs=any application_name=node01'"
echo 'systemctl start postgresql'
