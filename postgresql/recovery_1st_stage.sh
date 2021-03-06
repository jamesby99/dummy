#!/bin/bash
# This script is executed by "recovery_1st_stage" to recovery a Standby node.

set -o xtrace
exec > >(logger -i -p local1.info) 2>&1

#------------------------------------------------------------------------------
# 환경에 맞추어 수정해야 할 내용들
#------------------------------------------------------------------------------
SSH_KEY=ssh_private_key
PG_CONF=/etc/postgresql/11/main
__PG_LOG__="/var/log/postgresql/postgresql-11-main.log"


PRIMARY_NODE_PGDATA="$1"
DEST_NODE_HOST="$2"
DEST_NODE_PGDATA="$3"
PRIMARY_NODE_PORT="$4"
DEST_NODE_ID="$5"
DEST_NODE_PORT="$6"

PRIMARY_NODE_HOST=$(hostname)
PGHOME=/usr/lib/postgresql/11
ARCHIVEDIR=/postgresql/archive
REPLUSER=replica
REPL_SLOT_NAME=${DEST_NODE_HOST//[-.]/_}

logger -i -p local1.info recovery_1st_stage: start: pg_basebackup for Standby node $DEST_NODE_ID

## Test passwrodless SSH
ssh -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null postgres@${DEST_NODE_HOST} -i ~/.ssh/${SSH_KEY} ls /tmp > /dev/null

if [ $? -ne 0 ]; then
    logger -i -p local1.info recovery_1st_stage: passwrodless SSH to postgres@${DEST_NODE_HOST} failed. Please setup passwrodless SSH.
    exit 1
fi

## Get PostgreSQL major version
PGVERSION=`${PGHOME}/bin/initdb -V | awk '{print $3}' | sed 's/\..*//' | sed 's/\([0-9]*\)[a-zA-Z].*/\1/'`
if [ $PGVERSION -ge 12 ]; then
    RECOVERYCONF=${DEST_NODE_PGDATA}/myrecovery.conf
else
    RECOVERYCONF=${DEST_NODE_PGDATA}/recovery.conf
fi

## Create replication slot "${REPL_SLOT_NAME}"
${PGHOME}/bin/psql -p ${PRIMARY_NODE_PORT} << EOQ
SELECT pg_create_physical_replication_slot('${REPL_SLOT_NAME}');
EOQ

## Execute pg_basebackup to recovery Standby node
ssh -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null postgres@$DEST_NODE_HOST -i ~/.ssh/${SSH_KEY} "

    set -o errexit

    rm -rf $DEST_NODE_PGDATA
    rm -rf $ARCHIVEDIR/*

    ${PGHOME}/bin/pg_basebackup -h $PRIMARY_NODE_HOST -U $REPLUSER -p $PRIMARY_NODE_PORT -D $DEST_NODE_PGDATA -X stream

    cat > ${RECOVERYCONF} << EOT
primary_conninfo = 'host=${PRIMARY_NODE_HOST} port=${PRIMARY_NODE_PORT} user=${REPLUSER} application_name=${DEST_NODE_HOST} passfile=''/var/lib/postgresql/.pgpass'''
recovery_target_timeline = 'latest'
restore_command = 'scp ${PRIMARY_NODE_HOST}:${ARCHIVEDIR}/%f %p'
primary_slot_name = '${REPL_SLOT_NAME}'
EOT

    if [ ${PGVERSION} -ge 12 ]; then
        sed -i -e \"\\\$ainclude_if_exists = '$(echo ${RECOVERYCONF} | sed -e 's/\//\\\//g')'\" \
               -e \"/^include_if_exists = '$(echo ${RECOVERYCONF} | sed -e 's/\//\\\//g')'/d\" ${PG_CONF}/postgresql.conf
        touch ${DEST_NODE_PGDATA}/standby.signal
    else
        echo \"standby_mode = 'on'\" >> ${RECOVERYCONF}
    fi

#모든 node의 포트가 동일하므로 불필요함, 또한 postgres 위치도 틀림.
#    sed -i \"s/#*port = .*/port = ${DEST_NODE_PORT}/\" ${PG_CONF}/postgresql.conf
"

if [ $? -ne 0 ]; then

    ${PGHOME}/bin/psql -p ${PRIMARY_NODE_PORT} << EOQ
SELECT pg_drop_replication_slot('${REPL_SLOT_NAME}');
EOQ

    logger -i -p local1.error recovery_1st_stage: end: pg_basebackup failed. online recovery failed
    exit 1
fi

logger -i -p local1.info recovery_1st_stage: end: recovery_1st_stage complete
exit 0
