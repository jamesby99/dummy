#!/usr/bin/env bash

# postgresql 중지
systemctl stop postgresql


# db 저장소 변경 - 사전 /postgresql에 disk가 마운트 되어 있어야 한다. -----------------
rm -rf /postgresql/archive/*
rm -rf /postgresql/main/*
chown -R postgres:postgres /postgresql


# Replication 설정 --------------------------------------------------------------------
sed -i.bak -r "s/#hot_standby = on/hot_standby = on/g" /etc/postgresql/12/main/postgresql.conf
sed -i.bak -r "s/#max_replication_slots = 10/max_replication_slots = 2/g" /etc/postgresql/12/main/postgresql.conf
sed -i.bak -r "s/#hot_standby_feedback = off/hot_standby_feedback = on/g" /etc/postgresql/12/main/postgresql.conf
sed -i.bak -r "s/#primary_slot_name = ''/primary_slot_name = 'replication_slot'/g" /etc/postgresql/12/main/postgresql.conf
sed -i.bak -r "s/#recovery_target_timeline = 'latest'/recovery_target_timeline = 'latest'/g" /etc/postgresql/12/main/postgresql.conf
# -------------------------------------------------------------------------------------

echo '아래 작업은 수작업으로 진행합니다.'
echo 'su - postgres'
echo 'pg_basebackup -R -h < MASTER IP > -U replica -D /postgresql/main -P'
echo 'exit'

echo 'vi /var/lib/postgresql/12/main/postgresql.auto.conf'
echo '# add [application_name] to auto generated auth file (any name you like, like hostname and so on)'
echo "primary_conninfo = 'user=replica password=imdb21** host=< MASTER IP > port=5432 sslmode=prefer sslcompression=0 gssencmode=prefer krbsrvname=postgres target_session_attrs=any application_name=master'"

echo 'systemctl start postgresql'

echo '마스터 노드에서 아래 명령어로 동기화 확인'
echo 'psql -c "select usename, application_name, client_addr, state, sync_priority, sync_state from pg_stat_replication;"'
