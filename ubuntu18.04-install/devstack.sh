#!/bin/bash

sed -i.bak -r 's/([a-z]{2}.)?(archive|security).ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list

