#!/usr/bin/env bash

if [ -z "$1" ]; then
	echo ">>>>> usage		: redis.sh  <redis version>"
	echo ">>>>> example	: redis.sh  5.0.10"
	exit
fi

__REDIS_VERSION__=$1

echo '>>>>> [Redis] 커널 파라미터(overcommit_memory, TCP backlog관련) 수정'
sysctl -w vm.overcommit_memory=1
echo "vm.overcommit_memory=1" >> /etc/sysctl.conf
sysctl -w net.ipv4.tcp_max_syn_backlog=65536
echo "net.ipv4.tcp_max_syn_backlog=65536" >> /etc/sysctl.conf
sysctl -w net.core.somaxconn=65535
echo "net.core.somaxconn=65535" >> /etc/sysctl.conf

echo '>>>>> [Redis] THP 비활성화'
echo never > /sys/kernel/mm/transparent_hugepage/enabled
cat >> /etc/rc.local << EOF
#!/bin/bash
echo never > /sys/kernel/mm/transparent_hugepage/enabled
EOF
chmod 755 /etc/rc.local
systemctl enable rc.local.service


echo '>>>>> [Redis] 필요 패키지(build-essential pkg-config gcc tcl) 설치'
apt-get update -y
apt-get install  build-essential pkg-config gcc tcl libsystemd-dev -y
 
echo ">>>>> [Redis] redis-${__REDIS_VERSION__}.tar.gz 다운로드 및 압축해제"
wget https://download.redis.io/releases/redis-${__REDIS_VERSION__}.tar.gz
tar xvzf redis-${__REDIS_VERSION__}.tar.gz

echo '>>>>> [Redis] make clean, make, make test, make install'
cd ./redis-${__REDIS_VERSION__}
make distclean
make USE_SYSTEMD=yes
make test
make install
cd ..

echo '>>>>> [Redis] 계정 생성 및 sudoers 권한 부여 '
useradd -s /bin/bash -d /home/redis -m redis
echo "redis ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/redis

echo '>>>>> [Redis] 설정, 데이터, 로그, PID 디렉토리 생성 '
mkdir /etc/redis
mkdir /var/log/redis
mkdir /var/lib/redis
mkdir /var/run/redis

echo '>>>>> [Redis] 설정파일 복사'
cp ./conf/redis.conf /etc/redis/

chown -R redis:redis /etc/redis/
chown -R redis:redis /var/log/redis
chown -R redis:redis /var/lib/redis
chown -R redis:redis /var/run/redis


echo '>>>>> [Redis] redis.service 설정'
cat >> /etc/systemd/system/redis.service <<EOF
[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
Type=notify
User=redis
Group=redis
LimitNOFILE=65536
ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
ExecStop=/usr/local/bin/redis-cli shutdown
TimeoutStartSec=900
TimeoutStopSec=900
RestartSec=5s
Restart=on-success 
#on-success은 종료가 성공한 경우만 재시작함
#Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo '>>>>>  [Redis] 서비스 실행 및 자동 실행 설정'
systemctl daemon-reload
systemctl start redis
systemctl enable redis
