#!/bin/sh
set -e
echo Init success >> /tmp/log.txt


sgdisk --zap-all /dev/nvme0n1
#dd if=/dev/zero of=/dev/sda bs=1M count=100 oflag=direct,dsync
blkdiscard /dev/nvme0n1

echo "Making file system on root device" >> /tmp/log.txt
mkfs.ext4 /dev/nvme0n1
echo "Mounting" >> /tmp/log.txt 
mount /dev/nvme0n1 /mnt
echo "Enabling crio, configured to use /mnt for container runtimes" >> /tmp/log.txt
systemctl enable --now crio 
echo "Starting up the join..." >> /tmp/log.txt
UUID=$(cat /sys/class/dmi/id/product_uuid)
echo "arch-$UUID" > /etc/hostname
kubeadm join --config /etc/kubeadm/kubeadm.conf.yaml
echo "Join operation complete." >> /tmp/log.txt
