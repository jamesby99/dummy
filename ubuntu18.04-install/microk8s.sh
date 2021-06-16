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
172.27.0.33 k8s-1
172.27.0.4 k8s-2
172.27.0.126 k8s-3
EOF

# 공통 로그 설정
mkdir -p /imdb-log/nack-logs
chomd 777 -R /imdb-log

# TIME-ZONE(Asia/Seoul) 설정
timedatectl set-timezone Asia/Seoul

echo '>>>>> MicroK8s 설치 latest/stable 버전'
apt install snapd -y
snap install microk8s --classic

# CLI alias
echo '>>>>>  alias 설정: kubectl, helm'
echo 'alias k=microk8s.kubectl' >> /etc/profile
echo 'alias kubectl=microk8s.kubectl' >> /etc/profile
echo 'alias helm=microk8s.helm3' >> /etc/profile

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
echo '{"insecure-registries" : ["k8s-1:32000"]}' >> /etc/docker/daemon.json
systemctl restart docker

# root가 아닌 계정에 microk8s 실행 권한 부여
if [ ! -z $__USER__ ]; then
	echo ">>>>> $__USER__에 microk8s 실행 권한 부여 "
	usermod -a -G microk8s $__USER__
	chown -f -R $__USER__ ~/.kube
	
	usermod -aG docker $__USER__
fi

# register mirror 등록 및 containerd 재시작
sed -i.bak -r 's/localhost:32000/k8s-1:32000/g' /var/snap/microk8s/current/args/containerd-template.toml
echo '>>>>>  microk8s restart가 수동으로 필요합니다.'
echo 'microk8s stop 하세요'
echo 'microk8s start 하세요'
