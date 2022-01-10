#!/bin/bash

wget https://repo.percona.com/apt/percona-release_latest.$( lsb_release -sc )_all.deb
dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
percona-release setup ps80
apt-get update -y
apt-get install percona-xtrabackup-80 qpress  -y


