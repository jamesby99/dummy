#!/bin/bash

sudo killall apt apt-get
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
sudo rm /var/lib/dpkg/lock

sed -i.bak -r 's/([a-z]{2}.)?(archive|security).ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list

sudo apt -y update
sudo apt -y upgrade

sudo timedatectl set-timezone Asia/Seoul
