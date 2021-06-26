#!/usr/bin/env bash

# TOD
# 1. 성능튜닝 vCore, Mem에 따라 재설정 필요
# 2. 접근제한 할 것
# 3. Replica 연결 없는 경우 WRITE 중지 해결 방법은?

#------------------------------------------------------------------------------
# postgresql master 설정.
# 설정후, replica 로 stream replication이 동작되지 않으면 read only로만 동작합니다.
#------------------------------------------------------------------------------
if [ -z "$1" ]; || [ -z "$2" ]; then
	echo ">>>>> usage	: postgresql.sh <MS app 계정> <node 번호>"
	echo ">>>>> example	: postgresql.sh projection 1"
	exit
fi

echo -n 'postgresql master 설정입니다.'
echo -n 'DB 전용 DISK 마운트는 했나요? 했다면 엔터. 안했다면 ctrl-c.'
read

__USER__=$1
__NODE_NO__=$2

#------------------------------------------------------------------------------
# postgresql-12 리포지토리 및 사이닝키 추가후 설치
#------------------------------------------------------------------------------
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
apt update -y
apt install postgresql-12 -y

sleep 5

#------------------------------------------------------------------------------
# OS 사용자 생성 - ms app계정, replica (복제전용계정), postgres sudoer
#------------------------------------------------------------------------------
useradd -s /bin/bash -d /home/$__USER__ -m $__USER__
useradd -s /bin/bash -d /home/replica -m replica
useradd -s /bin/bash -d /home/pgpool -m pgpool
echo "postgres ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/postgres

#------------------------------------------------------------------------------
# DB 사용자 및 테이블 생성은 다음 절차를 따른다. : 참고 OS와 DB사용자를 일치시켜라!!!'
#------------------------------------------------------------------------------
sudo -u postgres createuser replica --replication
sudo -u postgres psql -c "alter user replica with password 'imdb21**';"

sudo -u postgres createuser pgpool --login
sudo -u postgres psql -c "alter user pgpool with password 'imdb21**';"

sudo -u postgres createuser $__USER__
sudo -u postgres psql -c "alter user $__USER__ with password 'imdb21**';"

sudo -u postgres psql -c "alter postgres with password 'imdb21**';"

sudo -u postgres createdb db_projection -O $__USER__
sudo -u postgres createdb db_order -O $__USER__
sudo -u postgres createdb db_configuration -O $__USER__
sudo -u postgres createdb db_backupmgt -O $__USER__
sudo -u postgres createdb db_servermgt -O $__USER__

#------------------------------------------------------------------------------
# 서버 중지
#------------------------------------------------------------------------------
systemctl stop postgresql

#------------------------------------------------------------------------------
# db 저장소 변경 - 사전 /postgresql에 disk가 마운트 되어 있어야 한다.
#------------------------------------------------------------------------------
mkdir -p /postgresql/archive
mv /var/lib/postgresql/12/main /postgresql
chown -R postgres:postgres /postgresql
sed -i.bak -r "s#data_directory = '/var/lib/postgresql/12/main'#data_directory = '/postgresql/main'#g" /etc/postgresql/12/main/postgresql.conf


#------------------------------------------------------------------------------
# 성능 튜닝
#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
# 스트리밍 replication 설정
#------------------------------------------------------------------------------
sed -i.bak -r "s/#wal_level = replica/wal_level = replica/g" /etc/postgresql/12/main/postgresql.conf
sed -i.bak -r "s/#max_wal_senders = 10/max_wal_senders = 5/g" /etc/postgresql/12/main/postgresql.conf
sed -i.bak -r "s/#wal_keep_segments = 0/wal_keep_segments = 32/g" /etc/postgresql/12/main/postgresql.conf
sed -i.bak -r "s/#wal_log_hints = off/wal_log_hints = on/g" /etc/postgresql/12/main/postgresql.conf

sed -i.bak -r "s/#archive_mode = off/archive_mode = on/g" /etc/postgresql/12/main/postgresql.conf
sed -i.bak -r "s/#archive_timeout = 0/archive_timeout = 120/g" /etc/postgresql/12/main/postgresql.conf
echo "archive_command = 'cp %p /postgresql/archive/arch_%f.arc'" >> /etc/postgresql/12/main/postgresql.conf

# pgpool 온라인 복구 모드로 시작할 수 있도록
sed -i.bak -r "s/#hot_standby = on/hot_standby = on/g" /etc/postgresql/12/main/postgresql.conf
     
# 동기화 방식을 쓸 경우 아래 활성화. default 비동기 방식임
#sed -i.bak -r "s/#synchronous_commit = on/synchronous_commit = on/g" /etc/postgresql/12/main/postgresql.conf
#sed -i.bak -r "s/#synchronous_standby_names = ''/synchronous_standby_names = '*'/g" /etc/postgresql/12/main/postgresql.conf

#wal_level = replica
#archive_mode = on
#archive_command = 'cp %p /postgresql/archive/arch_%f.arc'
#archive_timeout = 120
#synchronous_commit = on
#max_wal_senders = 2
#wal_keep_segments = 32
#synchronous_standby_names = '*'
#max_replication_slots = 10

# -------------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# 외부접속 IP 설정 - 접근제한 없이 설정, 상용에서는 접근 제한 필요
# 대상: replica, pgpool, base-station, micro-service
#------------------------------------------------------------------------------
sed -i.bak -r "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/12/main/postgresql.conf
# [변경전] 127.0.0.1:5432          0.0.0.0:*               LISTEN      24517/postgres
# [변경후] 0.0.0.0:5432            0.0.0.0:*               LISTEN      26412/postgres
echo "# 여기서부터는 커스텀마이징 설정입니다." >> /etc/postgresql/12/main/pg_hba.conf
# 일단 모두 연다.
echo "host    replication     replica         0.0.0.0/0               trust" >> /etc/postgresql/12/main/pg_hba.conf
echo "host    all             all             0.0.0.0/0               trust" >> /etc/postgresql/12/main/pg_hba.conf
# 상용에서는 replca 서버에 대한 소스 필터 제한을 해야 한다. - 
# echo "host    replication     replica         0.0.0.0/0               md5" >> /etc/postgresql/12/main/pg_hba.conf



# 서버 재시작
systemctl start postgresql


#------------------------------------------------------------------------------
# replication_slot 생성
# 일단 안되니...
#------------------------------------------------------------------------------
# sudo -u postgres psql -c "SELECT * FROM pg_create_physical_replication_slot('replication_slot');"


echo '생성결과는 다음의 명령어로 확인하세요'
echo 'su - postgres'
echo 'psql -c "select * from pg_user;"'
echo 'psql -l'
echo 'psql -c "show data_directory;"' #변경 디렉토리 확인
