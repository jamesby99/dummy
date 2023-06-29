#!/usr/bin/env bash

if [ -z "$1" ]; then
	echo ">>>>> usage	: temurin-jdk.sh <java version>"
	echo ">>>>> example	: temurin-jdk.sh 17"
	exit
fi

__JAVA_VER__=$1

echo ">>>>> jdk $__JAVA_VER__ 설치 "
sudo apt install -y wget apt-transport-https
sudo mkdir -p /etc/apt/keyrings
sudo wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/apt/keyrings/adoptium.asc
sudo echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list
sudo apt update
sudo apt install temurin-$__JAVA_VER__-jdk
sudo update-java-alternatives -s temurin-$__JAVA_VER__-jdk-amd64
java --version

echo '>>>>> JAVA_HOME 설정'
echo "export JAVA_HOME=/usr/lib/jvm/temurin-$__JAVA_VER__-jdk-amd64" >> /etc/profile
export JAVA_HOME=/usr/lib/jvm/temurin-$__JAVA_VER__-jdk-amd64
source /etc/profile
