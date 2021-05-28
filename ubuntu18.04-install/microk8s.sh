#!/usr/bin/env bash

__USER__=$1

echo '>>>>> MicroK8s 설치 latest/stable 버전'
snap install microk8s --classic

# CLI alias
echo '>>>>>  alias k=microk8s.kubectl 설정'
echo 'alias k=microk8s.kubectl' >> /etc/profile
echo 'alias kubectl=microk8s.kubectl' >> /etc/profile

# 필요한 애드온들 활성화
echo '>>>>>  dns, dashboard, ingress, metallb 애드온 활성화'
microk8s enable dns
microk8s enable dashboard
microk8s enable ingress
# microk8s enable metallb 는 별도 입력값(10.0.2.15-10.0.2.15)이 있기 때문에 수작업을 해야 한다.

if [ ! -z $__USER__ ]; then
	# root가 아닌 계정에 microk8s 실행 권한 부여
	echo ">>>>> $__USER__에 microk8s 실행 권한 부여 "
	usermod -a -G microk8s $__USER__
	chown -f -R $__USER__ ~/.kube
fi
