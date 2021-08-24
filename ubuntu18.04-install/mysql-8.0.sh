#!/bin/bash

# https://awakening95.tistory.com/2


wget https://dev.mysql.com/get/mysql-apt-config_0.8.18-1_all.deb
dpkg -i mysql-apt-config_0.8.18-1_all.deb

# GUI 선택 -> 그냥 OK

apt update -y

apt install mysql-server -y
# GUI 

mysql_secure_installation
# interative menu

