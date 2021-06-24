#!/usr/bin/env bash

if [ -z "$1" ]; then
	echo ">>>>> usage	: postgresql.sh <db 계정>"
	echo ">>>>> example	: postgresql.sh unbuntu"
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

# 스트리밍 replication 설정  ----------------------------------------------------------
sed -i.bak -r "s/#wal_level = replica/wal_level = replica/g" /etc/postgresql/12/main/postgresql.conf
sed -i.bak -r "s/#synchronous_commit = on/synchronous_commit = on/g" /etc/postgresql/12/main/postgresql.conf
sed -i.bak -r "s/#max_wal_senders = 10/max_wal_senders = 10/g" /etc/postgresql/12/main/postgresql.conf
sed -i.bak -r "s/#wal_keep_segments = 0/wal_keep_segments = 10/g" /etc/postgresql/12/main/postgresql.conf
sed -i.bak -r "s/#synchronous_standby_names = ''/synchronous_standby_names = '*'/g" /etc/postgresql/12/main/postgresql.conf

#wal_level = replica
#synchronous_commit = on
#max_wal_senders = 10
#wal_keep_segments = 10
#synchronous_standby_names = '*'

# 상용에서는 replca 서버에 대한 소스 필터 제한을 해야 한다. - 
echo "host    replication     replica         0.0.0.0/0               md5" >> /etc/postgresql/12/main/pg_hba.conf
# -------------------------------------------------------------------------------------


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

# DB 사용자 및 테이블 생성은 다음 절차를 따른다. : 참고 OS와 DB사용자를 일치시켜라!!!'
sudo -u postgres createuser replica --replication
sudo -u postgres psql -c "alter user replica with password 'imdb21**'
sudo -u postgres createuser $__USER__
sudo -u postgres psql -c "alter user $__USER__ with password 'imdb21**';"
sudo -u postgres createdb db_projection -O $__USER__
sudo -u postgres createdb db_order -O $__USER__
sudo -u postgres createdb db_configuration -O $__USER__
sudo -u postgres createdb db_backupmgt -O $__USER__
sudo -u postgres createdb db_servermgt -O $__USER__
# db 저장소 변경 - 사전 /postgresql에 disk가 마운트 되어 있어야 한다. -----------------
systemctl stop postgresql
cp -rf /var/lib/postgresql/12/main /postgresql
chown -R postgres:postgres /postgresql
sed -i.bak -r "s#data_directory = '/var/lib/postgresql/12/main'#data_directory = '/postgresql/main'#g" /etc/postgresql/12/main/postgresql.conf

systemctl start postgresql
# -------------------------------------------------------------------------------------

echo '생성결과는 다음의 명령어로 확인하세요'
echo 'su - postgres'
echo 'psql -c "select * from pg_user;"'
echo 'psql -l'
echo 'psql -c "show data_directory;"' #변경 디렉토리 확인
