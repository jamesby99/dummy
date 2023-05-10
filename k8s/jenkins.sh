#!/bin/bash


# 설치 환경에 맞게 IP주소 셋팅 필요합니다.
echo '>>>>>  cluster hostname 등록'
cat >> /etc/hosts <<EOF
172.25.0.44 k1 dev-k8s-1
172.25.0.35 k2 dev-k8s-2
172.25.0.121 k3 dev-k8s-3
172.25.0.175 pr
172.25.0.98 jk
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

# java 설치
apt-get -y install openjdk-17-jdk


echo "export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" >> /etc/profile
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
source /etc/profile

# Docker 설치
apt install docker.io -y
chmod 777 /var/run/docker.sock
chown root:docker /var/run/docker.sock

# kubectl 설치
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# helm 설치
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh

# Jenkins 설치를 위해 Repository key 추가
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

#  서버의 sources.list에 Jenkins 패키지 저장소를 추가
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# 패키지 인덱스 정보 업데이트
sudo apt-get update -y

# Jenkins 패키지 설치
sudo apt-get install jenkins  -y

#jenkins 계정 docker group에 추가
sudo usermod -aG docker jenkins

