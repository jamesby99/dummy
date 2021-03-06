#!/bin/bash
# This script is run after recovery_1st_stage to start Standby node.

set -o xtrace
exec > >(logger -i -p local1.info) 2>&1

#------------------------------------------------------------------------------
# 환경에 맞추어 수정해야 할 내용들
#------------------------------------------------------------------------------
SSH_KEY=ssh_private_key
PG_CONF=/etc/postgresql/11/main
__PG_LOG__="/var/log/postgresql/postgresql-11-main.log"


DEST_NODE_HOST="$1"
DEST_NODE_PGDATA="$2"

PGHOME=/usr/lib/postgresql/11

logger -i -p local1.info pgpool_remote_start: start: remote start Standby node $DEST_NODE_HOST

## Test passwrodless SSH
ssh -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null postgres@${DEST_NODE_HOST} -i ~/.ssh/${SSH_KEY} ls /tmp > /dev/null

if [ $? -ne 0 ]; then
    logger -i -p local1.info pgpool_remote_start: passwrodless SSH to postgres@${DEST_NODE_HOST} failed. Please setup passwrodless SSH.
    exit 1
fi

## Start Standby node
ssh -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null postgres@$DEST_NODE_HOST -i ~/.ssh/${SSH_KEY} "
    $PGHOME/bin/pg_ctl -l ${__PG_LOG__} -w -D $PG_CONF start
"

if [ $? -ne 0 ]; then
    logger -i -p local1.error pgpool_remote_start: $DEST_NODE_HOST PostgreSQL start failed.
    exit 1
fi

logger -i -p local1.info pgpool_remote_start: end: $DEST_NODE_HOST PostgreSQL started successfully.
exit 0
