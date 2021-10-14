#!/bin/bash

# 사전 작업
# 1. Cloud Init
# 2. java 11 설치

# Jenkins 설치를 위해 Repository key 추가
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -

#  서버의 sources.list에 Jenkins 패키지 저장소를 추가
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

# 패키지 인덱스 정보 업데이트
sudo apt-get update -y

# Jenkins 패키지 설치
sudo apt-get install jenkins  -y

# 만약 포트 변경이 필요하다면
# sudo vi /etc/default/jenkins
# HTTP_PORT=8080

