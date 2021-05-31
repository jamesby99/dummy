#!/usr/bin/env bash
__JAVA_VER__=8
#__JAVA_VER__=11

echo ">>>>> jdk $__JAVA_VER__ 설치 "
apt-get -y install openjdk-$__JAVA_VER__-jdk > /dev/null

echo '>>>>> JAVA_HOME 설정'
echo "export JAVA_HOME=/usr/lib/jvm/java-$__JAVA_VER__-openjdk-amd64" >> /etc/profile
export JAVA_HOME=/usr/lib/jvm/java-$__JAVA_VER__-openjdk-amd64
source /etc/profile
