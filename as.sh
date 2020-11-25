#!/usr/bin/env bash

__MYID__=$1         # zookeeper myid 주입

__POST_FIX__=48

if [ ${__MYID__} -eq 1 ]; then
	__POST_FIX__=49
fi

if [ ${__MYID__} -eq 2 ]; then
	__POST_FIX__=50
fi

echo '>>>>> zookeeper myid 생성 '
echo $__MYID__ > /opt/kafka/storage/zookeeper-data/myid

echo '>>>>> zookeeper zookeeper.properties 설정 추가 '
cat >>  /opt/kafka/config/zookeeper.properties <<EOF
# 팔로워가 리더와 초기에 연결하는 시간에 대한 타임아웃
initLimit=5
# 팔로워가 리더와 동기화 하는데에 대한 타임아웃. 즉 이 틱 시간안에 팔로워가 리더와 동기화가 되지 않는다면 제거 된다.
syncLimit=2

#2888 : 동기화를 위한 포트
#3888 : 클러스터 구성 시, leader를 선출하기 위한 포트
server.1=10.10.76.48:2888:3888
server.2=10.10.76.49:2888:3888
server.3=10.10.76.50:2888:3888
EOF


echo '>>>>> kafka broker server.properties 설정 추가 '
cat >> /opt/kafka/config/server.properties <<EOF
listeners=PLAINTEXT://:9092
advertised.listeners=PLAINTEXT://10.10.76.$__POST_FIX__:9092
zookeeper.connect=10.10.76.48:2181, 10.10.76.49:2181, 10.10.76.50:2181
EOF
sed -i.bak -r "s/broker.id=0/broker.id=$__MYID__/g" /opt/kafka/config/server.properties
