#!/usr/bin/env bash

# root에서 실행 할 것.
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] ; then
	echo ">>>>> usage	: private-registry.sh <추가 권한부여 계정> <private ip> <레지스트리 용량>"
	echo ">>>>> example	: private-registry.sh unbuntu 10.10.10.1 250" 
	exit
fi
__USER__=$1
__PR_IP__=$2
__SIZE__=$3

# 설치 환경에 맞게 IP주소 셋팅 필요합니다.
echo '>>>>>  cluster hostname 등록'
cat >> /etc/hosts <<EOF
${__PR_IP__} pr
EOF

# apt lock 사전 제거
killall apt apt-get
rm /var/lib/apt/lists/lock
rm /var/cache/apt/archives/lock
rm /var/lib/dpkg/lock

apt update
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
echo '>>>>>  dns, registry 애드온 활성화'
microk8s enable dns
microk8s enable registry:size=${__SIZE__}Gi

echo '>>>>> Docker 설치'
apt install docker.io -y

# http 로 registry 허용
echo '{"insecure-registries" : ["pr:32000"]}' >> /etc/docker/daemon.json
systemctl restart docker

mkdir -p /var/snap/microk8s/current/args/certs.d/pr:32000
touch /var/snap/microk8s/current/args/certs.d/pr:32000/hosts.toml
cat >> /var/snap/microk8s/current/args/certs.d/pr:32000/hosts.toml <<EOF
server = "http://pr:32000"
[host."pr:32000"]
capabilities = ["pull", "resolve"]
EOF

chown -R root:microk8s /var/snap/microk8s/current/args/certs.d/pr:32000
chmod 770 /var/snap/microk8s/current/args/certs.d/pr:32000
chmod 660 /var/snap/microk8s/current/args/certs.d/pr:32000/hosts.toml

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
