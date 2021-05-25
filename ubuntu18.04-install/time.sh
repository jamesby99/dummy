#!/usr/bin/env bash
#참고: https://webdir.tistory.com/208

###############################################################################
echo '>>>>> timezone를 서울로 변경'
timedatectl set-timezone Asia/Seoul

###############################################################################
echo ">>>>> ntp 설치 및 ntp 서버 설정"
apt-get install ntp -y
cat >> /etc/ntp.conf <<EOF # http://www.pool.ntp.org/ko/zone/kr  에서 서버 정보 확인하고 수정 반영
server 1.kr.pool.ntp.org
server 3.asia.pool.ntp.org
server 2.asia.pool.ntp.org
EOF
systemctl restart ntp
echo ">>>>> ntp 동작확인"
echo "---------------------------------------------"
echo "* 는 현재 sync 를 받고 있음을 의미"
echo "+ 는 ntp 알고리즘에 의해 접속은 가능하지만 sync 를 하고 있지는 않음을 의미"
echo "- 는 ntp 알고리즘에 의해 접속은 가능하지만 sync 가능 리스트에서 제외"
echo "blank는 접속이 불가능함을 의미"
echo "remote 는 sync 를 하는 straum 2 서버주소"
echo "refid 는 각 straum 2 서버가 현재 sync 를 하고 있는 straum 1 서버를 보여줌"
echo "st 가 16일 경우 해당 서버에 접속 할 수 없음"
echo "NTP는 udp 포트 123 를 사용하니 열어준다."
echo "---------------------------------------------"
ntpq -p
echo "수초후에 ntpq -p 다시하여 확인할 것"


