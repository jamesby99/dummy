#!/bin/bash
if [ -z "$1" ]; then
  echo "error vip-attach"
  return
fi
echo "[[ VIP Attach ]]"
vipaddr=$1
vipnic=`ip a | grep 2: | ( read num nic description; echo $nic )`
#echo $vipnic
sudo ip a a $vipaddr/32 dev $vipnic
echo "ip a a $vipaddr/32 dev $vipnic" | sudo tee -a /etc/rc.local
#sudo ip a | grep 2: | ( read num nic description; echo $nic )
sudo ip a
echo "$(date +"%Y-%m-%d-%H:%M:%S") VIP ATTACH - $vipaddr" >> /home/dbaas/mysql/viphistory.log
sudo ip a >> /home/dbaas/mysql/viphistory.log
echo "EXIT"
exit
