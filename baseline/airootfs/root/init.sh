#!/bin/bash
set -e
echo Init success >> /tmp/log.txt


mkdir /config
# Mount the second device
mount -o ro,noload /dev/sda2 /config
source /config/*.sh

echo "


All scrips complete.

"

