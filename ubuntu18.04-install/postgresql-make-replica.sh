#!/usr/bin/env bash

if [ -z "$1" ]; then
	echo ">>>>> usage	: ./postgresql-make-replica.sh <MASTER IP>"
	echo ">>>>> example	: ./postgresql-make-replica.sh 172.27.0.10"
	exit
fi

echo -n 'postgresql master 설정입니다.'
echo -n 'DB 전용 DISK 마운트는 했나요? 했다면 엔터. 안했다면 ctrl-c.'
read

__MASTER_IP__=$1

# postgresql 중지
systemctl stop postgresql


# db 저장소 변경 - 사전 /postgresql에 disk가 마운트 되어 있어야 한다. -----------------
rm -rf /postgresql/archive/*
rm -rf /postgresql/main/*
chown -R postgres:postgres /postgresql


# Replication 설정 --------------------------------------------------------------------
sed -i.bak -r "s/#hot_standby = on/hot_standby = on/g" /etc/postgresql/12/main/postgresql.conf
sed -i.bak -r "s/#primary_conninfo = ''/primary_conninfo = 'host=$__MASTER_IP__ port=5432 user=replica'/g" /etc/postgresql/12/main/postgresql.conf
sed -i.bak -r "s/#recovery_target_timeline = 'latest'/recovery_target_timeline = 'latest'/g" /etc/postgresql/12/main/postgresql.conf

#sed -i.bak -r "s/#max_replication_slots = 10/max_replication_slots = 2/g" /etc/postgresql/12/main/postgresql.conf
#sed -i.bak -r "s/#hot_standby_feedback = off/hot_standby_feedback = on/g" /etc/postgresql/12/main/postgresql.conf
#sed -i.bak -r "s/#primary_slot_name = ''/primary_slot_name = 'replication_slot'/g" /etc/postgresql/12/main/postgresql.conf

# -------------------------------------------------------------------------------------

echo '아래 작업은 수작업으로 진행합니다.'
echo 'su - postgres'
echo 'pg_basebackup -R -h < MASTER IP > -U replica -D /postgresql/main -P'
echo 'exit'

# postgresql 다시시작
echo 'systemctl start postgresql'

echo 'vi /var/lib/postgresql/12/main/postgresql.auto.conf'
echo '# add [application_name] to auto generated auth file (any name you like, like hostname and so on)'
echo "primary_conninfo = 'host=$__MASTER_IP__ port=5432 user=replica'"

echo '마스터 노드에서 아래 명령어로 동기화 확인'
echo 'psql -c "select usename, application_name, client_addr, state, sync_priority, sync_state from pg_stat_replication;"'
