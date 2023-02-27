#!/bin/bash

swapoff -v /swap.img
rm -rf /swap.img

fallocate -l 30G /swap.img
chmod 600 /swap.img
mkswap /swap.img
swapon /swap.img
swapon -show