#!/bin/sh
set -e
echo Init success >> /tmp/log.txt


sgdisk --zap-all /dev/nvme0n1
#dd if=/dev/zero of=/dev/sda bs=1M count=100 oflag=direct,dsync
blkdiscard /dev/nvme0n1
mkfs.ext4 /dev/nvme0n1
mount /dev/nvme0n1 /mnt

systemctl enable --now crio 
export UUID=$(cat /sys/class/dmi/id/board_serial)
envsubst < /etc/kubeadm/kubeadm.conf.yaml | sponge /etc/kubeadm/kubeadm.conf.yaml
echo $UUID > /etc/hostname
echo "127.0.0.1 $UUID" > /etc/hosts
echo "::1 $UUID" >> /etc/hosts


modprobe br_netfilter
echo '1' > /proc/sys/net/ipv4/ip_forward




kubeadm join --config /etc/kubeadm/kubeadm.conf.yaml
echo "Join operation complete." >> /tmp/log.txt
