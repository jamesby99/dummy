#!/usr/bin/env bash

#------------------------------------------------------------------------------
# [ 실행전 TODO, 꼭 확인할 것 ]
# 1. DB 전용 Volume을 추가 작업을 사전에 해서 /postgresql/main 에 마운트
# 2. /etc/hosts에 적용할 IP주소 수정
# 3. ssh private key값 수정
# 4. vCore, Memory, Disk Type에 따른 성능 튜닝 values 수정
# 5. virtual IP(__VIP__) 값 수정
# 6. pg_hba 값 
#------------------------------------------------------------------------------

if [ -z "$1" ] || [ -z "$2" ] ; then
	echo ">>>>> usage	: postgresql.sh <MS app 계정> <node 번호>"
	echo ">>>>> example	: postgresql.sh projection 1"
	exit
fi

__USER__=$1
__NODE_NO__=$2


__VIP__="172.25.0.133"
__SSH_PRIVATE_KEY__="-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAux8GQv26mDRMH70fCYcFmuYUZEx2DjUWmTNtwyEddxe2iQuk
Omx7PkC7c4e9ZRwX9EmM8uIgQ9tY1pNCeys2z3FrYAvSjT/pJ0YIkFHyFIQ60GK0
uuvK0rDF54F5WVq4IEaHEtyEeUIx3czZ2F4pQNwnvt1qc0Att3+vmZjeSMAQ/fQC
8ywmOec4AmWL0YZJIM7VSYvfUYR7bN9pFo2BSqAVwSBF498ir63PW4lAwkpWboe/
erIfvpzam6u3En7wbCJsjUh0TUZ02rAOhMx1Yur2U4L5bLjwwSGMv20mIFoERQ9N
HyF8Wld6h38PZ9eWPqv2EAClE+zDd4F/6ie3dQIDAQABAoIBACjjqamf6lNyMiRJ
Xmvljmr/1fro3m9SWILXwyd9qAOrMd8WpSeDJxc+a/fd9JwQnIdsPxmgIi7R0sLo
4QErO0nvXehaDQOCsL89RYfL8FtdXcDFoPqrpeGOcWCaYVsOQOgEoWWUvHoG5gCy
z/PA98DNmv3RQn62yoarp0KoLgK1Xar31XfLpQcBPts/x94A0JvWR4Kar30utipx
aJkY06e7iXPXsmrbXa/K4cKJtl0jVjT3fRAc5OUjpUT059L4apguO8B3G0UF9wy7
7OOmX/rpwTV5T0QpKOwBaACdY4CbHb/Ada8N11orNK+w4YJjkh3Bf3zlfLXyAZZP
ISVaxe0CgYEA8LEatM4MwDhbgXxbXf0psiS1RSY1WIuw3fS0bDyS9dSYKvjL3c7Y
hmxiv1XLDoDlyZvo/d6HwsZQv4xU+keCLUrPfGckKCaiLQ6s3xoMeSG7MOueVETR
EBePZBNpCNpwp804TruW4wJmAHZBPJoTB1vdqHIaIN17tNn9722KkO8CgYEAxwWx
qq1RFB+ANBMfV4mqCO5/kwSkRFAOlNCSU8XOoNSgYHz6+BR+ULLmW6pe/cZOF4QY
1HVScM++xZ7XzhTBtU0tL30OgvS6aNGpYjpNOqLdbssTsvKXpjkpaAF0pAV1RORp
+qAvTL7PDO/pKOy+xnTE4NXRCWXaerR0JbSn9dsCgYACkEBSkKc+HNuMo4Btndal
2RI9LE0BJmu50XNie7qs95ivTHsPX7aap+jdVNKW0vSfkxOGMKqNfoM5pwr4p25R
gSx4jLir3M15YWCh96sOVzehK8FB8IGxhC64yCQkPf9ZKixhWkofHNVtR9UmChYN
zAKuWpjApNs+b9vuguIo7QKBgFN7PfUb0iCgvgQZ6VGsuxgYAodGsSi+c/9UJazi
EjRAPC18/0DER9/Nyva0VjgY0HTowgmMVNJhMeJvKJKW/lHwV33N9SJVSUPifixn
zDFGU5+/qzmqrJXa8FViFu0eJPyK2zF3s597ghopICI8fCF+pX6x8YcBpE1IGFgg
mTt1AoGBAN1yNLzyomruSWHBxxJ/hKRbDLoncIByzFWAJzvmsav6m9XahunOLqcU
y0RlFHmwZidVyOB7SK8gi9o7QKI1SVG5FD6nb2Jc7rRuyAvEsD3fRAeGVl8CBXYi
rQMpUosmLBa8AfcQI4VNDede02NDPsKVl28daFiqqyr6e9In8bFk
-----END RSA PRIVATE KEY-----"


__PG_HOME__="/var/lib/postgresql"
__PG_BIN__="/usr/lib/postgresql/11/bin"
__PG_CONF__="/etc/postgresql/11/main"
__PG_LOG__="/var/log/postgresql/postgresql-11-main.log"

echo -n 'postgresql node 설정입니다.'
echo -n 'DB 전용 DISK 마운트는 했나요? 했다면 엔터. 안했다면 ctrl-c.'
read
cd ~

#------------------------------------------------------------------------------
# postgresql-11.12 리포지토리 및 사이닝키 추가후 설치
# postgresql-11.12, pgpool-4.1.4(extend포함), arping
#------------------------------------------------------------------------------
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
apt update -y
apt install postgresql-11 -y
sleep 5
apt install pgpool2 -y
apt install postgresql-11-pgpool2 -y
apt install iputils-arping -y 


#------------------------------------------------------------------------------
# /etc/hosts 설정
#-----------------------------------------------------------------------------
# cat >> /etc/hosts << EOF
# # Postgresql DB cluster
# 172.27.0.82      pg-1
# 172.27.0.201      pg-2
# 172.27.0.214      pg-3
# $__VIP__          pg-vip
# EOF


#------------------------------------------------------------------------------
# OS 사용자 생성 - ms app계정, replica (복제전용계정), postgres sudoer
#------------------------------------------------------------------------------
useradd -s /bin/bash -d /home/$__USER__ -m $__USER__
#useradd -s /bin/bash -d /home/replica -m replica # 삭제해도 되지 않을까?
#useradd -s /bin/bash -d /home/pgpool -m pgpool	 # 삭제해도 되지 않을까?
echo "postgres ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/postgres



#------------------------------------------------------------------------------
# postgresql 부팅시 자동 실행 제거 및 start, stop 전용 스크립트 제공
#------------------------------------------------------------------------------
systemctl disable postgresql
systemctl disable pgpool2
systemctl daemon-reload

cat > $__PG_HOME__/start-pg.sh << EOF
#!/bin/bash
TMP_DIR="/var/run/postgresql/11-main.pg_stat_tmp"
if [ ! -e \$TMP_DIR ]; then
  mkdir -p \$TMP_DIR
fi

$__PG_BIN__/pg_ctl start -D $__PG_CONF__ -l $__PG_LOG__
EOF

cat > $__PG_HOME__/stop-pg.sh << EOF
#!/bin/bash
$__PG_BIN__/pg_ctl stop -D $__PG_CONF__ -m fast
EOF

chmod 700 $__PG_HOME__/*.sh
chown postgres:postgres $__PG_HOME__/*.sh



#------------------------------------------------------------------------------
# ssh 키 sharing : root -> postgres, postgres <-> postgres
#------------------------------------------------------------------------------
cat > .ssh/ssh_private_key << EOF
${__SSH_PRIVATE_KEY__}
EOF
chmod 600 .ssh/*

cp -R .ssh $__PG_HOME__
chown -R postgres:postgres $__PG_HOME__/.ssh
chmod 600 $__PG_HOME__/.ssh/*
chmod 700 $__PG_HOME__/.ssh



#------------------------------------------------------------------------------
# .pgpass for postgres : PG 명령어들을 interactive 없이 바로 실행할 수 있도록...
#------------------------------------------------------------------------------
cat > $__PG_HOME__/.pgpass << EOF
pg-1:5432:replication:replica:imdb21**
pg-2:5432:replication:replica:imdb21**
pg-3:5432:replication:replica:imdb21**
pg-1:5432:postgres:postgres:imdb21**
pg-2:5432:postgres:postgres:imdb21**
pg-3:5432:postgres:postgres:imdb21**
EOF

chmod 600 $__PG_HOME__/.pgpass
chown postgres:postgres $__PG_HOME__/.pgpass


#------------------------------------------------------------------------------
# DB 사용자 및 테이블 생성은 다음 절차를 따른다. : 참고 OS와 DB사용자를 일치시켜라!!!'
#------------------------------------------------------------------------------
chmod 755 /root # WARN제거: could not change directory to "/root": Permission denied

sudo -u postgres createuser replica --replication  --login
sudo -u postgres psql -c "alter user replica with password 'imdb21**';"

sudo -u postgres createuser pgpool --login
sudo -u postgres psql -c "alter user pgpool with password 'imdb21**';"
sudo -u postgres psql -c "grant pg_monitor to pgpool;"

sudo -u postgres createuser $__USER__
sudo -u postgres psql -c "alter user $__USER__ with password 'imdb21**';"

sudo -u postgres psql -c "alter user postgres with password 'imdb21**';"

sudo -u postgres createdb db_projection -O $__USER__
sudo -u postgres createdb db_order -O $__USER__
sudo -u postgres createdb db_configuration -O $__USER__
sudo -u postgres createdb db_backupmgt -O $__USER__
sudo -u postgres createdb db_servermgt -O $__USER__
sudo -u postgres createdb db_monitoring -O $__USER__
sudo -u postgres createdb db_admin -O $__USER__


#------------------------------------------------------------------------------
# 서버 중지
#------------------------------------------------------------------------------
systemctl stop pgpool2
systemctl stop postgresql
sleep 5


#------------------------------------------------------------------------------
# db 저장소 변경 - 사전 /postgresql에 disk가 마운트 되어 있어야 한다.
#------------------------------------------------------------------------------
mkdir -p /postgresql/archive
mv /var/lib/postgresql/11/main /postgresql
chown -R postgres:postgres /postgresql
sed -i.bak -r "s#data_directory = '/var/lib/postgresql/11/main'#data_directory = '/postgresql/main'#g" $__PG_CONF__/postgresql.conf



#------------------------------------------------------------------------------
# 성능 튜닝 : 2vCore 2GB 기준
#------------------------------------------------------------------------------
# https://pgtune.leopard.in.ua/#/ 에 값을 추가하여 작성할 것

sed -i.bak -r "s/max_connections = 100/max_connections = 350/g" $__PG_CONF__/postgresql.conf
sed -i.bak -r "s/shared_buffers = 128MB/shared_buffers = 512MB/g" $__PG_CONF__/postgresql.conf
sed -i.bak -r "s/#effective_cache_size = 4GB/effective_cache_size = 1536MB/g" $__PG_CONF__/postgresql.conf
sed -i.bak -r "s/#maintenance_work_mem = 64MB/maintenance_work_mem = 128MB/g" $__PG_CONF__/postgresql.conf
sed -i.bak -r "s/#checkpoint_completion_target = 0.5/checkpoint_completion_target = 0.9/g" $__PG_CONF__/postgresql.conf
sed -i.bak -r "s/#wal_buffers = -1/wal_buffers = 16MB/g" $__PG_CONF__/postgresql.conf
sed -i.bak -r "s/#default_statistics_target = 100/default_statistics_target = 100/g" $__PG_CONF__/postgresql.conf
sed -i.bak -r "s/#random_page_cost = 4.0/random_page_cost = 4/g" $__PG_CONF__/postgresql.conf
sed -i.bak -r "s/#effective_io_concurrency = 1/effective_io_concurrency = 2/g" $__PG_CONF__/postgresql.conf
sed -i.bak -r "s/#work_mem = 4MB/work_mem = 1497kB/g" $__PG_CONF__/postgresql.conf
sed -i.bak -r "s/min_wal_size = 80MB/min_wal_size = 1GB/g" $__PG_CONF__/postgresql.conf
sed -i.bak -r "s/max_wal_size = 1GB/max_wal_size = 4GB/g" $__PG_CONF__/postgresql.conf
sed -i.bak -r "s/#max_worker_processes = 8/max_worker_processes = 2/g" $__PG_CONF__/postgresql.conf
sed -i.bak -r "s/#max_parallel_workers_per_gather = 2/max_parallel_workers_per_gather = 1/g" $__PG_CONF__/postgresql.conf
sed -i.bak -r "s/#max_parallel_workers = 8/max_parallel_workers = 2/g" $__PG_CONF__/postgresql.conf
sed -i.bak -r "s/#max_parallel_maintenance_workers = 2/max_parallel_maintenance_workers = 1/g" $__PG_CONF__/postgresql.conf


# 스펙 ----------------------------------------------
# DB Version: 11
# OS Type: linux
# DB Type: web
# Total Memory (RAM): 2 GB
# CPUs num: 2
# Connections num: 350
# Data Storage: hdd
# 권장 -----------------------------------------------
# max_connections = 350
# shared_buffers = 512MB
# effective_cache_size = 1536MB
# maintenance_work_mem = 128MB
# checkpoint_completion_target = 0.9
# wal_buffers = 16MB
# default_statistics_target = 100
# random_page_cost = 4
# effective_io_concurrency = 2
# work_mem = 1497kB
# min_wal_size = 1GB
# max_wal_size = 4GB
# max_worker_processes = 2
# max_parallel_workers_per_gather = 1
# max_parallel_workers = 2
# max_parallel_maintenance_workers = 1

#------------------------------------------------------------------------------
# 스트리밍 replication 설정
#------------------------------------------------------------------------------
sed -i.bak -r "s/#wal_level = replica/wal_level = replica/g" $__PG_CONF__/postgresql.conf
sed -i.bak -r "s/#max_wal_senders = 10/max_wal_senders = 10/g" $__PG_CONF__/postgresql.conf
sed -i.bak -r "s/#wal_keep_segments = 0/wal_keep_segments = 32/g" $__PG_CONF__/postgresql.conf
sed -i.bak -r "s/#wal_log_hints = off/wal_log_hints = on/g" $__PG_CONF__/postgresql.conf
sed -i.bak -r "s/#max_replication_slots = 10/max_replication_slots = 10/g" $__PG_CONF__/postgresql.conf

sed -i.bak -r "s/#archive_mode = off/archive_mode = on/g" $__PG_CONF__/postgresql.conf
sed -i.bak -r "s/#archive_timeout = 0/archive_timeout = 120/g" $__PG_CONF__/postgresql.conf
echo "archive_command = 'cp %p /postgresql/archive/arch_%f.arc'" >> $__PG_CONF__/postgresql.conf

# pgpool 온라인 복구 모드로 시작할 수 있도록
sed -i.bak -r "s/#hot_standby = on/hot_standby = on/g" $__PG_CONF__/postgresql.conf
     
# 동기화 방식을 쓸 경우 아래 활성화. default 비동기 방식임
#sed -i.bak -r "s/#synchronous_commit = on/synchronous_commit = on/g" $__PG_CONF__/postgresql.conf
#sed -i.bak -r "s/#synchronous_standby_names = ''/synchronous_standby_names = '*'/g" $__PG_CONF__/postgresql.conf



#------------------------------------------------------------------------------
# pg_hba.conf 설정
#------------------------------------------------------------------------------
cat > $__PG_CONF__/pg_hba.conf << EOF
# "local" is for Unix domain socket connections only
local   all             all                                     trust
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
# IPv6 local connections:
host    all             all             ::1/128                 trust
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust
# same subnet
host    replication     all             172.25.0.0/24           trust
host    all             all             172.25.0.0/24           trust
EOF


sed -i.bak -r "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" $__PG_CONF__/postgresql.conf
# [변경전] 127.0.0.1:5432          0.0.0.0:*               LISTEN      24517/postgres
# [변경후] 0.0.0.0:5432            0.0.0.0:*               LISTEN      26412/postgres


#------------------------------------------------------------------------------
# pgpool 설정 파일 다운로드
#------------------------------------------------------------------------------
wget --quiet -O /etc/pgpool2/pgpool.conf https://github.com/jamesby99/dummy/raw/master/postgresql/pgpool-dev.conf
wget --quiet -O /etc/pgpool2/failover.sh https://github.com/jamesby99/dummy/raw/master/postgresql/failover.sh
wget --quiet -O /etc/pgpool2/follow_master.sh https://github.com/jamesby99/dummy/raw/master/postgresql/follow_master.sh
wget --quiet -O /etc/pgpool2/recovery_1st_stage https://github.com/jamesby99/dummy/raw/master/postgresql/recovery_1st_stage.sh
wget --quiet -O /etc/pgpool2/pgpool_remote_start https://github.com/jamesby99/dummy/raw/master/postgresql/pgpool_remote_start.sh

chmod 755 /etc/pgpool2/*.sh
chmod 755 /etc/pgpool2/recovery_1st_stage
chmod 755 /etc/pgpool2/pgpool_remote_start

cp /etc/pgpool2/recovery_1st_stage /postgresql/main
cp /etc/pgpool2/pgpool_remote_start /postgresql/main
chown postgres:postgres /postgresql/main/recovery_1st_stage
chown postgres:postgres /postgresql/main/pgpool_remote_start



#------------------------------------------------------------------------------
# pgpool.conf 설정
#------------------------------------------------------------------------------
sed -i.bak -r "s/delegate_IP = 'delegate_IP'/delegate_IP = '$__VIP__'/g" /etc/pgpool2/pgpool.conf
sed -i.bak -r "s/wd_hostname = 'wd_hostname'/wd_hostname = 'pg-$__NODE_NO__'/g" /etc/pgpool2/pgpool.conf

if [ $__USER__  != 'orders' ]; then
	sed -i.bak -r "s/sr_check_database = 'db_order'/sr_check_database = 'db_$__USER__'/g" /etc/pgpool2/pgpool.conf
fi

if [ $__NODE_NO__ == '1' ]; then
	sed -i.bak -r "s/heartbeat_destination0 = 'pg-x'/heartbeat_destination0 = 'pg-2'/g" /etc/pgpool2/pgpool.conf
	sed -i.bak -r "s/heartbeat_destination1 = 'pg-x'/heartbeat_destination1 = 'pg-3'/g" /etc/pgpool2/pgpool.conf
	sed -i.bak -r "s/other_pgpool_hostname0 = 'pg-x'/other_pgpool_hostname0 = 'pg-2'/g" /etc/pgpool2/pgpool.conf
	sed -i.bak -r "s/other_pgpool_hostname1 = 'pg-x'/other_pgpool_hostname1 = 'pg-3'/g" /etc/pgpool2/pgpool.conf	
elif [ $__NODE_NO__ == '2' ]; then
	sed -i.bak -r "s/heartbeat_destination0 = 'pg-x'/heartbeat_destination0 = 'pg-1'/g" /etc/pgpool2/pgpool.conf
	sed -i.bak -r "s/heartbeat_destination1 = 'pg-x'/heartbeat_destination1 = 'pg-3'/g" /etc/pgpool2/pgpool.conf
	sed -i.bak -r "s/other_pgpool_hostname0 = 'pg-x'/other_pgpool_hostname0 = 'pg-1'/g" /etc/pgpool2/pgpool.conf
	sed -i.bak -r "s/other_pgpool_hostname1 = 'pg-x'/other_pgpool_hostname1 = 'pg-3'/g" /etc/pgpool2/pgpool.conf	
elif [ $__NODE_NO__ == '3' ]; then
	sed -i.bak -r "s/heartbeat_destination0 = 'pg-x'/heartbeat_destination0 = 'pg-1'/g" /etc/pgpool2/pgpool.conf
	sed -i.bak -r "s/heartbeat_destination1 = 'pg-x'/heartbeat_destination1 = 'pg-2'/g" /etc/pgpool2/pgpool.conf
	sed -i.bak -r "s/other_pgpool_hostname0 = 'pg-x'/other_pgpool_hostname0 = 'pg-1'/g" /etc/pgpool2/pgpool.conf
	sed -i.bak -r "s/other_pgpool_hostname1 = 'pg-x'/other_pgpool_hostname1 = 'pg-2'/g" /etc/pgpool2/pgpool.conf	
fi



#------------------------------------------------------------------------------
# pcp.conf
#------------------------------------------------------------------------------
echo 'pgpool:62843c0232f945e8b2261d720f2c2670' >> /etc/pgpool2/pcp.conf		# id:md5 password
echo 'localhost:9898:pgpool:imdb21**' > ~/.pcppass
chmod 600 ~/.pcppass

    
#------------------------------------------------------------------------------
# postgresql 재시작
#------------------------------------------------------------------------------
systemctl start postgresql


#------------------------------------------------------------------------------
# postgresql 재시작후 해야할 작업들
#------------------------------------------------------------------------------
#echo -e "\n" | sudo -u postgres psql -c "SELECT * FROM pg_create_physical_replication_slot('replication_slot');"	# replication_slot 생성
sudo -u postgres psql template1 -c "CREATE EXTENSION pgpool_recovery;"							# ?
chmod 700 /root													 	# sudo -u postgres가 더이상 없음으로 원복


#------------------------------------------------------------------------------
# postgresql 종료
#------------------------------------------------------------------------------
systemctl stop postgresql

#------------------------------------------------------------------------------
# log 분리
#------------------------------------------------------------------------------
mkdir /var/log/pgpool
touch /var/log/pgpool/pgpool.log
chown -R root:postgres /var/log/pgpool
chmod -R 777 /var/log/pgpool
echo 'local0.*                       /var/log/pgpool/pgpool.log' >> /etc/rsyslog.d/50-default.conf
systemctl restart rsyslog.service


#------------------------------------------------------------------------------
# apt auto upgrade 끄기
#------------------------------------------------------------------------------
systemctl stop apt-daily.timer
systemctl disable apt-daily.timer
systemctl disable apt-daily.service

systemctl stop apt-daily-upgrade.timer
systemctl disable apt-daily-upgrade.timer
systemctl disable apt-daily-upgrade.service

systemctl daemon-reload


#------------------------------------------------------------------------------
echo '/etc/rsyslog.d/50-default.conf 에서 local0.none 추가 필요=> *.*;auth,authpriv.none,local0.none              -/var/log/syslog'
echo '생성결과는 다음의 명령어로 확인하세요'
echo 'su - postgres'
echo 'psql -c "select * from pg_user;"'
echo 'psql -l'
echo 'psql -c "show data_directory;"' #변경 디렉토리 확인

echo '#------------------------------------------------------------------------------'
echo 'WAL 파일 주기적 자동 삭제 등록 필요'
echo 'crontab -e'
echo '00 3 * * * find /postgresql/archive/* -mtime +1 -exec rm -rf {} \;'
