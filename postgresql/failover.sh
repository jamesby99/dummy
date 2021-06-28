#!/bin/bash
# This script is run by failover_command.

#------------------------------------------------------------------------------
# 환경에 맞추어 수정해야 할 내용들
#------------------------------------------------------------------------------
SSH_KEY=ssh_private_key
PG_CONF=/etc/postgresql/11/main
__PG_LOG__="/var/log/postgresql/postgresql-11-main.log"

set -o xtrace
exec > >(logger -i -p local1.info) 2>&1

# Special values:
#   %d = failed node id
#   %h = failed node hostname
#   %p = failed node port number
#   %D = failed node database cluster path
#   %m = new master node id
#   %H = new master node hostname
#   %M = old master node id
#   %P = old primary node id
#   %r = new master port number
#   %R = new master database cluster path
#   %N = old primary node hostname
#   %S = old primary node port number
#   %% = '%' character

FAILED_NODE_ID="$1"
FAILED_NODE_HOST="$2"
FAILED_NODE_PORT="$3"
FAILED_NODE_PGDATA="$4"
NEW_MASTER_NODE_ID="$5"
NEW_MASTER_NODE_HOST="$6"
OLD_MASTER_NODE_ID="$7"
OLD_PRIMARY_NODE_ID="$8"
NEW_MASTER_NODE_PORT="$9"
NEW_MASTER_NODE_PGDATA="${10}"
OLD_PRIMARY_NODE_HOST="${11}"
OLD_PRIMARY_NODE_PORT="${12}"

PGHOME=/usr/lib/postgresql/11
REPL_SLOT_NAME=${FAILED_NODE_HOST//[-.]/_}

logger -i -p local1.info failover.sh: start: failed_node_id=$FAILED_NODE_ID old_primary_node_id=$OLD_PRIMARY_NODE_ID failed_host=$FAILED_NODE_HOST new_master_host=$NEW_MASTER_NODE_HOST

## If there's no master node anymore, skip failover.
if [ $NEW_MASTER_NODE_ID -lt 0 ]; then
    logger -i -p local1.info failover.sh: All nodes are down. Skipping failover.
	exit 0
fi

## Test passwrodless SSH
ssh -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null postgres@${NEW_MASTER_NODE_HOST} -i ~/.ssh/${SSH_KEY} ls /tmp > /dev/null

if [ $? -ne 0 ]; then
    logger -i -p local1.info failover.sh: passwrodless SSH to postgres@${NEW_MASTER_NODE_HOST} failed. Please setup passwrodless SSH.
    exit 1
fi

## If Standby node is down, skip failover.
if [ $FAILED_NODE_ID -ne $OLD_PRIMARY_NODE_ID ]; then
    logger -i -p local1.info failover.sh: Standby node is down. Skipping failover.

    ssh -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null postgres@$OLD_PRIMARY_NODE_HOST -i ~/.ssh/${SSH_KEY} "
        ${PGHOME}/bin/psql -p $OLD_PRIMARY_NODE_PORT -c \"SELECT pg_drop_replication_slot('${REPL_SLOT_NAME}')\"
    "

    if [ $? -ne 0 ]; then
        logger -i -p local1.error failover.sh: drop replication slot "${REPL_SLOT_NAME}" failed
        exit 1
    fi

    exit 0
fi

## Promote Standby node.
logger -i -p local1.info failover.sh: Primary node is down, promote standby node ${NEW_MASTER_NODE_HOST}.

ssh -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    postgres@${NEW_MASTER_NODE_HOST} -i ~/.ssh/${SSH_KEY} ${PGHOME}/bin/pg_ctl -D ${PG_CONF} -w promote

if [ $? -ne 0 ]; then
    logger -i -p local1.error failover.sh: new_master_host=$NEW_MASTER_NODE_HOST promote failed
    exit 1
fi

logger -i -p local1.info failover.sh: end: new_master_node_id=$NEW_MASTER_NODE_ID started as the primary node
exit 0
