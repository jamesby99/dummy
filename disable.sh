#!/bin/bash
echo [[ Check APT Timer ]]
result=`systemctl list-timers | grep apt-daily`
echo $result
if [[ "$result" == *apt-daily.service* ]]; then
  echo Find APT Timer T.T
  sudo systemctl stop apt-daily.timer
  sudo systemctl disable apt-daily.timer
  sudo systemctl disable apt-daily.service
  sudo systemctl stop apt-daily-upgrade.timer
  sudo systemctl disable apt-daily-upgrade.timer
  sudo systemctl disable apt-daily-upgrade.service
  sudo systemctl daemon-reload
else
  echo No APT Timer!! ^^
fi
echo -----------------------
echo -e "\n"
echo [[ print ip a ]]
sudo ip a
echo --- Check Again VIP ---
return
