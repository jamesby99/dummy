#!/usr/bin/env bash

if [ -z "$1" ]; then
	echo ">>>>> usage		: sentinel.sh  <redis version>"
	echo ">>>>> example	: sentinel.sh  5.0.10"
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
echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.local


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

echo '>>>>> [Sentinel] 계정 생성 및 sudoers 권한 부여 '
useradd -s /bin/bash -d /home/sentinel -m sentinel
echo "sentinel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/sentinel

echo '>>>>> [Sentinel] 설정, 데이터, 로그, PID 디렉토리 생성 '
mkdir /etc/sentinel
mkdir /var/log/sentinel
mkdir /var/lib/sentinel
mkdir /var/run/sentinel

echo '>>>>> [Sentinel] 설정파일 복사'
cp ./conf/sentinel.conf /etc/sentinel/

chown -R sentinel:sentinel /etc/sentinel/
chown -R sentinel:sentinel /var/log/sentinel
chown -R sentinel:sentinel /var/lib/sentinel
chown -R sentinel:sentinel /var/run/sentinel

echo '>>>>> [Sentinel] redis.service 설정'
cat >> /etc/systemd/system/sentinel.service <<EOF
[Unit]
Description=Redis sentinel
After=network.target

[Service]
Type=notify
User=sentinel
Group=sentinel
LimitNOFILE=65536
ExecStart=/usr/local/bin/redis-sentinel /etc/sentinel/sentinel.conf
ExecStop=/usr/local/bin/redis-cli -p 26379 shutdown
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo '>>>>>  [Sentinel] 서비스 실행 및 자동 실행 설정'
systemctl daemon-reload
systemctl start sentinel
systemctl enable sentinel
