#!/bin/bash

killall apt apt-get
rm /var/lib/apt/lists/lock
rm /var/cache/apt/archives/lock
rm /var/lib/dpkg/lock*

sed -i.bak -r 's/([a-z]{2}.)?(archive|security).ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list
apt-get update && apt-get dist-upgrade -y

# 공통으로 필요한 패키지들...
PKG_GROUP1='tree wget curl unzip'
PKG_GROUP2='python3 python3-pip python3-dev python3-setuptools httpie '
PKG_GROUP3='python python-dev  python-pip python-setuptools '
apt-get -y install $PKG_GROUP1 $PKG_GROUP2 $PKG_GROUP3


wget https://bootstrap.pypa.io/get-pip.py
apt-get -y install python2.7-minimal
python2.7 get-pip.py


# python 교통정리
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1
update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1 

pip3 install --upgrade pip

# stack 계정 생성
useradd -s /bin/bash -d /opt/stack -m stack
echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack

cp -r ~/.ssh ~stack
chown -R stack:stack ~stack/

