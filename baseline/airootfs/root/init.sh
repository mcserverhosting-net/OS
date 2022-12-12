#!/bin/bash
set -e
echo Init success >> /tmp/log.txt

sleep 10s

#Gateway IP plus +10. Example: 192.168.0.11
#export source_address=$(ip route | awk '/default/ {print $3}' | awk -F '.' '{print $1 "." $2 "." $3 "." $4+10}')

#Gateway IP. Example: 192.168.0.1
export source_address=$(ip route | awk '/default/ { print $3 }')

#Script by MAC vs default init
#export mac=$(cat /sys/class/net/$(ip route show default | awk '/default/ {print $5}')/address | sed s/://g )
#curl -LO "http://$source_address/$mac.sh"
#sh $mac.sh

#A default init.sh that's local
#curl -LO "http://$source_address/init.sh"
#sh init.sh

curl -LO https://raw.githubusercontent.com/mcserverhosting-net/OS/main/init.sh
sh init.sh