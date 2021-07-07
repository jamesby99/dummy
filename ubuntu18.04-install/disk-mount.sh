#!/usr/bin/env bash

mkdir -p /redis-rdb

REDIS_DISK=$(lsblk -f | tail -n 1)

#interactive menu에서 stdin 처리
echo -e "n\n\n\n\n\ng\nw\n" | fdisk /dev/${REDIS_DISK}
echo -e "y\n" | mkfs.ext4 /dev/${REDIS_DISK}

UUID=$(blkid -o value /dev/${REDIS_DISK} | head -n 1)
echo "UUID=${UUID} /redis-rdb ext4 defaults 0 0" >> /etc/fstab

chown -R redis:redis /redis-rdb
mount -a
