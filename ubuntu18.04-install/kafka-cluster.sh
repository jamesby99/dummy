#!/usr/bin/env bash

#3대인 경우 __MYID__ = 1 | 2 | 3
if [ -z "$1" ] || [ -z "$2" ] ; then
	echo ">>>>> usage	: kafka-cluster.sh my-id my-ip"
	echo ">>>>> example	: kafka-cluster.sh 1 10.213.194.101"
	exit
fi

__MYID__=$1				# zookeeper myid 주입
__MYIP__=$2

__KAFKA_VER__=3.0.2			#https://downloads.apache.org/kafka 에서 현재 제공 버전이 맞는지 확인 필요
__SCOLA_VER__=2.13
__KAFKA__=kafka_$__SCOLA_VER__-$__KAFKA_VER__
__KAFKA_JVM_MEMORY__="-Xmx1G -Xms1G" 		#VM의 메모리에 따라 약 50% 정도 할당

# TIME-ZONE(Asia/Seoul) 설정
timedatectl set-timezone Asia/Seoul

###############################################################################
echo '>>>>> /etc/hosts에 kafka cluster ip 반영'
cat >> /etc/hosts <<EOF
172.25.0.51 kafka1
172.25.0.24 kafka2
172.25.0.162 kafka3
EOF

###############################################################################

echo '>>>>> kafka 계정 생성 및 sudoers 권한 부여 '
useradd -s /bin/bash -d /opt/kafka -m kafka
echo "kafka ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/kafka

###############################################################################

echo '>>>>> kafka-logs/zookeeper-data 디렉토리 생성 '
mkdir -p /opt/kafka/storage/zookeeper-data/
mkdir -p /opt/kafka/storage/kafka-logs/

###############################################################################
# G-Cloud Https 가 안되어 수동 다운로드
echo ">>>>> kafka/zookeeper 설치 ($__KAFKA__) "
wget -O ~/$__KAFKA__.tgz https://archive.apache.org/dist/kafka/$__KAFKA_VER__/$__KAFKA__.tgz --no-check-certificate
tar -xf ~/$__KAFKA__.tgz -C /opt/kafka --strip-components=1

###############################################################################

echo '>>>>> zookeeper myid 생성 '
echo $__MYID__ > /opt/kafka/storage/zookeeper-data/myid

###############################################################################

echo '>>>>> zookeeper zookeeper.properties에 data저장소 변경 '
sed -i.bak -r "s#/tmp/zookeeper#/opt/kafka/storage/zookeeper-data#g" /opt/kafka/config/zookeeper.properties

###############################################################################
echo '>>>>> zookeeper zookeeper.properties 설정 추가 '
cat >>  /opt/kafka/config/zookeeper.properties <<EOF
# 팔로워가 리더와 초기에 연결하는 시간에 대한 타임아웃
initLimit=5
# 팔로워가 리더와 동기화 하는데에 대한 타임아웃. 즉 이 틱 시간안에 팔로워가 리더와 동기화가 되지 않는다면 제거 된다.
syncLimit=2

#2888 : 동기화를 위한 포트
#3888 : 클러스터 구성 시, leader를 선출하기 위한 포트
server.1=kafka1:2888:3888
server.2=kafka2:2888:3888
server.3=kafka3:2888:3888
EOF

###############################################################################

echo '>>>>> kafka broker server.properties 설정 추가 '
# advertised.listeners= 상황에 따라 적절히 만들어 써야 한다.
# advertised.listeners=PLAINTEXT://211.184.188.38:1909$__MYID__
# advertised.listeners=PLAINTEXT://kafka$__MYID__:9092

cat >> /opt/kafka/config/server.properties <<EOF
# topic create 단계 없이 자동 생성 기능 off (휴먼에러 방지)
auto.create.topics.enable=false

listeners=PLAINTEXT://:9092
# advertised.listeners는 각각의 노드의 접근 엔드포인트로 
advertised.listeners=PLAINTEXT://$__MYIP__:9092
zookeeper.connect=kafka1:2181, kafka2:2181, kafka3:2181
EOF
sed -i.bak -r "s/broker.id=0/broker.id=$__MYID__/g" /opt/kafka/config/server.properties
sed -i.bak -r "s#/tmp/kafka-logs#/opt/kafka/storage/kafka-logs#g" /opt/kafka/config/server.properties

###############################################################################

echo '>>>>> /opt/kafka/~ user:group 일괄변경  '
chown -R kafka:kafka /opt/kafka

###############################################################################

echo '>>>>> zookeeper.service 설정'
cat > /etc/systemd/system/zookeeper.service <<EOF
[Unit]
Requires=network.target remote-fs.target
After=network.target remote-fs.target

[Service]
Type=simple
User=kafka
ExecStart=/opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties
ExecStop=/opt/kafka/bin/zookeeper-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF

###############################################################################

echo '>>>>> kafka.service  설정'
cat > /etc/systemd/system/kafka.service <<EOF
[Unit]
Requires=zookeeper.service
After=zookeeper.service

[Service]
Type=simple
User=kafka
Environment=KAFKA_HEAP_OPTS="-Xmx2G -Xms2G"
ExecStart=/bin/sh -c '/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties'
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF

###############################################################################

echo '>>>>>  zookeeper, kafka 서비스 실행 및 자동 실행 설정'
systemctl daemon-reload
systemctl start zookeeper
systemctl enable zookeeper
systemctl start kafka
systemctl enable kafka
