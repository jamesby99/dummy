#!/bin/bash

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
apt-get -y install openjdk-8-jdk
apt-get -y install openjdk-11-jdk


echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> /etc/profile
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
source /etc/profile

# Docker 설치
apt install docker.io -y
chmod 777 /var/run/docker.sock
chown root:docker /var/run/docker.sock

# Jenkins 설치를 위해 Repository key 추가
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -

#  서버의 sources.list에 Jenkins 패키지 저장소를 추가
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

# 패키지 인덱스 정보 업데이트
sudo apt-get update -y

# Jenkins 패키지 설치
sudo apt-get install jenkins  -y
