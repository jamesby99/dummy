#!/usr/bin/env bash

if [ -z "$1" ]; then
	echo ">>>>> usage	: java.sh <java version>"
	echo ">>>>> example	: java.sh 11"
	exit
fi

__JAVA_VER__=$1

echo ">>>>> jdk $__JAVA_VER__ 설치 "
apt-get -y install openjdk-$__JAVA_VER__-jdk > /dev/null

echo '>>>>> JAVA_HOME 설정'
echo "export JAVA_HOME=/usr/lib/jvm/java-$__JAVA_VER__-openjdk-amd64" >> /etc/profile
export JAVA_HOME=/usr/lib/jvm/java-$__JAVA_VER__-openjdk-amd64
source /etc/profile
