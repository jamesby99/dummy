#!/usr/bin/env bash

# nfs utils 설치
apt install nfs-common -y

# 수동 마운트
mount -t nfs k8s-3:/imdb-log /imdb-log

# 부팅시 자동 마운트
cat >> /etc/fstab << EOF
k8s-3:/imdb-log   /imdb-log               nfs     defaults        0 0
EOF



