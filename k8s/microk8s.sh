#!/usr/bin/env bash

if [ -z "$1" ]; then
	echo ">>>>> usage	: microk8s.sh <권한부여 계정>"
	echo ">>>>> example	: microk8s.sh unbuntu"
	exit
fi

__USER__=$1

# 설치 환경에 맞게 IP주소 셋팅 필요합니다.
echo '>>>>>  cluster hostname 등록'
cat >> /etc/hosts <<EOF
172.27.0.33 k1
172.27.0.4 k2
172.27.0.126 k3
EOF

# apt lock 사전 제거
killall apt apt-get
rm /var/lib/apt/lists/lock
rm /var/cache/apt/archives/lock
rm /var/lib/dpkg/lock

apt -update
apt -y upgrade

# TIME-ZONE(Asia/Seoul) 설정
timedatectl set-timezone Asia/Seoul

echo '>>>>> MicroK8s 설치 latest/stable 버전'
snap install microk8s --classic

# CLI alias
echo '>>>>>  alias 설정: kubectl, helm'
echo 'alias k=microk8s.kubectl' >> /etc/profile
echo 'alias kubectl=microk8s.kubectl' >> /etc/profile
echo 'alias h=microk8s.helm3' >> /etc/profile
echo 'alias helm=microk8s.helm3' >> /etc/profile


# 필요한 애드온들 활성화
echo '>>>>>  dns, dashboard, helm3, storage 애드온 활성화'
microk8s enable dns
microk8s enable dashboard
microk8s enable helm3
microk8s enable storage

echo '>>>>> Docker 설치'
apt install docker.io -y
echo '{"insecure-registries" : ["pr:32000"]}' >> /etc/docker/daemon.json
systemctl restart docker

# microk8s 실행 그룹 권한 부여
if [ ! -z $__USER__ ]; then
	echo ">>>>> $__USER__에 microk8s 실행 권한 부여 "
	usermod -a -G microk8s $__USER__
	chown -f -R $__USER__ ~/.kube
	
	usermod -aG docker $__USER__
fi

echo '>>>>>  microk8s restart가 수동으로 필요합니다.'
echo 'microk8s stop 하세요'
echo 'microk8s start 하세요'
