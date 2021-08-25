#!/usr/bin/env bash

if [ -z "$1" ] || [ -z "$2" ] ; then
	echo ">>>>> usage	: disk-mount.sh mount-path owner"
	echo ">>>>> example	: disk-mount.sh /redis-rdb redis"
	exit
fi

MOUNT_PATH=$1
OWNER=$2

mkdir -p ${MOUNT_PATH}

MOUNT_DISK=$(lsblk -f | tail -n 1)

#interactive menu에서 stdin 처리
echo -e "n\n\n\n\n\ng\nw\n" | fdisk /dev/${MOUNT_DISK}
echo -e "y\n" | mkfs.ext4 /dev/${MOUNT_DISK}

UUID=$(blkid -o value /dev/${MOUNT_DISK} | head -n 1)
echo "UUID=${UUID} ${MOUNT_PATH} ext4 defaults 0 0" >> /etc/fstab

mount -a
chown -R ${OWNER}:${OWNER} ${MOUNT_PATH}

