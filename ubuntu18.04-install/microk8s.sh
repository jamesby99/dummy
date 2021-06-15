#!/usr/bin/env bash

if [ -z "$1" ]; then
	echo ">>>>> usage	: microk8s.sh <권한부여 계정>"
	echo ">>>>> example	: microk8s.sh unbuntu"
	exit
fi

__USER__=$1

apt install snapd -y

echo '>>>>> MicroK8s 설치 latest/stable 버전'
snap install microk8s --classic

# CLI alias
echo '>>>>>  alias k=microk8s.kubectl 설정'
echo 'alias k=microk8s.kubectl' >> /etc/profile
echo 'alias kubectl=microk8s.kubectl' >> /etc/profile

# 필요한 애드온들 활성화
echo '>>>>>  dns, dashboard, helm3, storage, registry 애드온 활성화'
microk8s enable dns
microk8s enable dashboard
microk8s enable helm3
microk8s enable storage
microk8s enable registry
# microk8s enable metallb 는 별도 입력값(10.0.2.15-10.0.2.15)이 있기 때문에 수작업을 해야 한다.

echo '>>>>> Docker 설치'
apt install docker.io -y
echo '{"insecure-registries" : ["localhost:32000"]}' >> /etc/docker/daemon.json
systemctl restart docker

# root가 아닌 계정에 microk8s 실행 권한 부여
if [ ! -z $__USER__ ]; then
	echo ">>>>> $__USER__에 microk8s 실행 권한 부여 "
	usermod -a -G microk8s $__USER__
	chown -f -R $__USER__ ~/.kube
	
	usermod -aG docker $__USER__
fi
