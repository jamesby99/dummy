#!/bin/bash

microk8s stop

cp -rp /var/snap/microk8s/* /k8s
rm -rf /var/snap/microk8s
ln -s /k8s /var/snap/microk8s

microk8s start
