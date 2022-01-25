#!/usr/bin/env bash

# root에서 실행 할 것.
if [ -z "$1" ] || [ -z "$2" ] ; then
	echo ">>>>> usage	: private-registry.sh <추가 권한부여 계정> <private ip>"
	echo ">>>>> example	: private-registry.sh unbuntu 10.10.10.1"
	exit
fi
__USER__=$1
__PR_IP__=$2

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
microk8s enable registry:size=250Gi

echo '>>>>> Docker 설치'
apt install docker.io -y
echo '{"insecure-registries" : ["pr:32000"]}' >> /etc/docker/daemon.json
systemctl restart docker

# root가 아닌 계정에 microk8s 실행 권한 부여
if [ ! -z $__USER__ ]; then
	echo ">>>>> $__USER__에 microk8s 실행 권한 부여 "
	usermod -a -G microk8s $__USER__
	chown -f -R $__USER__ ~/.kube
	
	usermod -aG docker $__USER__
fi

# register mirror 등록 및 containerd 재시작
sed -i.bak -r 's/localhost:32000/pr:32000/g' /var/snap/microk8s/current/args/containerd-template.toml

mkdir -p /var/snap/microk8s/current/args/certs.d/${__PR_IP__}:32000
touch /var/snap/microk8s/current/args/certs.d/${__PR_IP__}:32000/hosts.toml
cat >> /var/snap/microk8s/current/args/certs.d/${__PR_IP__}:32000/hosts.toml <<EOF
server = "http://${__PR_IP__}:32000"
[host."${__PR_IP__}:32000"]
capabilities = ["pull", "resolve"]
EOF

echo '>>>>>  microk8s restart가 수동으로 필요합니다.'
echo 'microk8s stop 하세요'
echo 'microk8s start 하세요'
