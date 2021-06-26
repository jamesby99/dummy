#!/bin/bash
# This script is run after failover_command to synchronize the Standby with the new Primary.
# First try pg_rewind. If pg_rewind failed, use pg_basebackup.

set -o xtrace
exec > >(logger -i -p local1.info) 2>&1

#------------------------------------------------------------------------------
# 환경에 맞추어 수정해야 할 내용들
#------------------------------------------------------------------------------
SSH_KEY=ssh_private_key


# Special values:
# 1)  %d = node id
# 2)  %h = hostname
# 3)  %p = port number
# 4)  %D = database cluster path
# 5)  %m = new primary node id
# 6)  %H = new primary node hostname
# 7)  %M = old master node id
# 8)  %P = old primary node id
# 9)  %r = new primary port number
# 10) %R = new primary database cluster path
# 11) %N = old primary node hostname
# 12) %S = old primary node port number
# 13) %% = '%' character

NODE_ID="$1"
NODE_HOST="$2"
NODE_PORT="$3"
NODE_PGDATA="$4"
NEW_MASTER_NODE_ID="$5"
NEW_MASTER_NODE_HOST="$6"
OLD_MASTER_NODE_ID="$7"
OLD_PRIMARY_NODE_ID="$8"
NEW_MASTER_NODE_PORT="$9"
NEW_MASTER_NODE_PGDATA="${10}"

PGHOME=/usr/lib/postgresql/12
ARCHIVEDIR=/postgresql/archive
REPLUSER=replica
PCP_USER=pgpool
PGPOOL_PATH=/usr/sbin
PCP_PORT=9898
REPL_SLOT_NAME=${NODE_HOST//[-.]/_}

logger -i -p local1.info follow_master.sh: start: Standby node ${NODE_ID}

## Test passwrodless SSH
ssh -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null postgres@${NEW_MASTER_NODE_HOST} -i ~/.ssh/${SSH_KEY} ls /tmp > /dev/null

if [ $? -ne 0 ]; then
    logger -i -p local1.info follow_master.sh: passwrodless SSH to postgres@${NEW_MASTER_NODE_HOST} failed. Please setup passwrodless SSH.
    exit 1
fi

## Get PostgreSQL major version
PGVERSION=`${PGHOME}/bin/initdb -V | awk '{print $3}' | sed 's/\..*//' | sed 's/\([0-9]*\)[a-zA-Z].*/\1/'`

if [ $PGVERSION -ge 12 ]; then
    RECOVERYCONF=${NODE_PGDATA}/myrecovery.conf
else
    RECOVERYCONF=${NODE_PGDATA}/recovery.conf
fi

## Check the status of Standby
ssh -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
postgres@${NODE_HOST} -i ~/.ssh/${SSH_KEY} ${PGHOME}/bin/pg_ctl -w -D ${NODE_PGDATA} status


## If Standby is running, synchronize it with the new Primary.
if [ $? -eq 0 ]; then

    logger -i -p local1.info follow_master.sh: pg_rewind for node $NODE_ID

    # Create replication slot "${REPL_SLOT_NAME}"
    ${PGHOME}/bin/psql -h ${NEW_MASTER_NODE_HOST} -p ${NEW_MASTER_NODE_PORT} \
        -c "SELECT pg_create_physical_replication_slot('${REPL_SLOT_NAME}');"  >/dev/null 2>&1

    if [ $? -ne 0 ]; then
        logger -i -p local1.error follow_master.sh: create replication slot \"${REPL_SLOT_NAME}\" failed. You may need to create replication slot manually.
    fi

    ssh -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null postgres@${NODE_HOST} -i ~/.ssh/${SSH_KEY} "

        set -o errexit

        ${PGHOME}/bin/pg_ctl -w -m f -D ${NODE_PGDATA} stop

        ${PGHOME}/bin/pg_rewind -D ${NODE_PGDATA} --source-server=\"user=postgres host=${NEW_MASTER_NODE_HOST} port=${NEW_MASTER_NODE_PORT}\"

        rm -rf ${NODE_PGDATA}/pg_replslot/*

        cat > ${RECOVERYCONF} << EOT
primary_conninfo = 'host=${NEW_MASTER_NODE_HOST} port=${NEW_MASTER_NODE_PORT} user=${REPLUSER} application_name=${NODE_HOST} passfile=''/var/lib/pgsql/.pgpass'''
recovery_target_timeline = 'latest'
restore_command = 'scp ${NEW_MASTER_NODE_HOST}:${ARCHIVEDIR}/%f %p'
primary_slot_name = '${REPL_SLOT_NAME}'
EOT

        if [ ${PGVERSION} -ge 12 ]; then
            sed -i -e \"\\\$ainclude_if_exists = '$(echo ${RECOVERYCONF} | sed -e 's/\//\\\//g')'\" \
                   -e \"/^include_if_exists = '$(echo ${RECOVERYCONF} | sed -e 's/\//\\\//g')'/d\" ${NODE_PGDATA}/postgresql.conf
            touch ${NODE_PGDATA}/standby.signal
        else
            echo \"standby_mode = 'on'\" >> ${RECOVERYCONF}
        fi

        ${PGHOME}/bin/pg_ctl -l /dev/null -w -D ${NODE_PGDATA} start

    "

    if [ $? -ne 0 ]; then
        logger -i -p local1.error follow_master.sh: end: pg_rewind failed. Try pg_basebackup.

        ssh -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null postgres@${NODE_HOST} -i ~/.ssh/${SSH_KEY} "

            set -o errexit

            # Execute pg_basebackup
            rm -rf ${NODE_PGDATA}
            rm -rf ${ARCHIVEDIR}/*
            ${PGHOME}/bin/pg_basebackup -h ${NEW_MASTER_NODE_HOST} -U $REPLUSER -p ${NEW_MASTER_NODE_PORT} -D ${NODE_PGDATA} -X stream

            cat > ${RECOVERYCONF} << EOT
primary_conninfo = 'host=${NEW_MASTER_NODE_HOST} port=${NEW_MASTER_NODE_PORT} user=${REPLUSER} application_name=${NODE_HOST} passfile=''/var/lib/pgsql/.pgpass'''
recovery_target_timeline = 'latest'
restore_command = 'scp ${NEW_MASTER_NODE_HOST}:${ARCHIVEDIR}/%f %p'
primary_slot_name = '${REPL_SLOT_NAME}'
EOT

            if [ ${PGVERSION} -ge 12 ]; then
                sed -i -e \"\\\$ainclude_if_exists = '$(echo ${RECOVERYCONF} | sed -e 's/\//\\\//g')'\" \
                       -e \"/^include_if_exists = '$(echo ${RECOVERYCONF} | sed -e 's/\//\\\//g')'/d\" ${NODE_PGDATA}/postgresql.conf
                touch ${NODE_PGDATA}/standby.signal
            else
                echo \"standby_mode = 'on'\" >> ${RECOVERYCONF}
            fi
        "

        if [ $? -ne 0 ]; then
            # drop replication slot
            ssh -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null postgres@${NEW_MASTER_NODE_HOST} -i ~/.ssh/${SSH_KEY} "
                ${PGHOME}/bin/psql -p ${NEW_MASTER_NODE_PORT} -c \"SELECT pg_drop_replication_slot('${REPL_SLOT_NAME}')\"
            "

            logger -i -p local1.error follow_master.sh: end: pg_basebackup failed
            exit 1
        fi

        # start Standby node on ${NODE_HOST}
        ssh -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                postgres@${NODE_HOST} -i ~/.ssh/${SSH_KEY} $PGHOME/bin/pg_ctl -l /dev/null -w -D ${NODE_PGDATA} start

    fi

    # If start Standby successfully, attach this node
    if [ $? -eq 0 ]; then

        # Run pcp_attact_node to attach Standby node to Pgpool-II.
        ${PGPOOL_PATH}/pcp_attach_node -w -h localhost -U $PCP_USER -p ${PCP_PORT} -n ${NODE_ID}

        if [ $? -ne 0 ]; then
                logger -i -p local1.error follow_master.sh: end: pcp_attach_node failed
                exit 1
        fi

    # If start Standby failed, drop replication slot "${REPL_SLOT_NAME}"
    else

        ${PGHOME}/bin/psql -h ${NEW_MASTER_NODE_HOST} -p ${NEW_MASTER_NODE_PORT} \
            -c "SELECT pg_drop_replication_slot('${REPL_SLOT_NAME}');"  >/dev/null 2>&1

        if [ $? -ne 0 ]; then
            logger -i -p local1.error follow_master.sh: drop replication slot \"${REPL_SLOT_NAME}\" failed. You may need to drop replication slot manually.
        fi

        logger -i -p local1.error follow_master.sh: end: follow master command failed
        exit 1
    fi

else
    logger -i -p local1.info follow_master.sh: failed_nod_id=${NODE_ID} is not running. skipping follow master command
    exit 0
fi

logger -i -p local1.info follow_master.sh: end: follow master command complete
exit 0
