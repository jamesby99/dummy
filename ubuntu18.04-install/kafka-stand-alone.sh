#!/usr/bin/env bash

if [ -z "$1" ] ; then
	echo ">>>>> usage	: kafka-stand-alone.sh my-ip"
	echo ">>>>> example	: kafka-cluster.sh 10.213.194.101"
	exit
fi

__MYIP__=$1

__MYID__=0         # zookeeper myid 주입
__KAFKA_VER__=2.5.1
__KAFKA__=kafka_2.13-$__KAFKA_VER__

###############################################################################

echo '>>>>> kafka 계정 생성 및 sudoers 권한 부여 '
useradd -s /bin/bash -d /opt/kafka -m kafka
echo "kafka ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/kafka

###############################################################################

echo '>>>>> kafka-logs/zookeeper-data 디렉토리 생성 '
mkdir -p /opt/kafka/storage/zookeeper-data/
mkdir -p /opt/kafka/storage/kafka-logs/

###############################################################################

echo ">>>>> kafka/zookeeper 설치 ($__KAFKA__) "
wget https://downloads.apache.org/kafka/$__KAFKA_VER__/$__KAFKA__.tgz
tar -xf ~/$__KAFKA__.tgz -C /opt/kafka --strip-components=1

###############################################################################

echo '>>>>> zookeeper zookeeper.properties에 data저장소 변경 '
sed -i.bak -r "s#/tmp/zookeeper#/opt/kafka/storage/zookeeper-data#g" /opt/kafka/config/zookeeper.properties

###############################################################################

echo '>>>>> zookeeper myid 생성 '
echo $__MYID__ > /opt/kafka/storage/zookeeper-data/myid

###############################################################################

echo '>>>>> kafka broker server.properties 설정 추가 '
cat >> /opt/kafka/config/server.properties <<EOF
# topic 삭제 가능 기능 활성화, 미설정 상태에서 삭제하면 오동작
delete.topic.enable = true

# topic create 단계 없이 자동 생성 기능 off (휴먼에러 방지)
auto.create.topics.enable=false

listeners=PLAINTEXT://:9092
# advertised.listeners는 각각의 노드의 접근 엔드포인트로 
advertised.listeners=PLAINTEXT://$__MYIP__:9092

EOF
sed -i.bak -r "s#/tmp/kafka-logs#/opt/kafka/storage/kafka-logs#g" /opt/kafka/config/server.properties

###############################################################################

echo '>>>>> /opt/kafka/~ user:group 일괄변경  '
chown -R kafka:kafka /opt/kafka

###############################################################################

echo '>>>>> zookeeper.service 설정'
cat >> /etc/systemd/system/zookeeper.service <<EOF
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
cat >> /etc/systemd/system/kafka.service <<EOF
[Unit]
Requires=zookeeper.service
After=zookeeper.service

[Service]
Type=simple
User=kafka
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
