#!/usr/bin/env bash

apt install nfs-kernel-server -y

cat > /etc/exports << EOF
/imdb-log *(rw,no_root_squash)
EOF

mkdir -p /imdb-log/nack-logs
chmod 777 -R /imdb-log

systemctl restart nfs-server
