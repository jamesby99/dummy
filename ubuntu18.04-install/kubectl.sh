#!/bin/bash

# 최신 버전의 kubectl 바이너리 다운로드
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# kubectl 인스톨
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# kubectl 버전 확인
sudo kubectl version --client
