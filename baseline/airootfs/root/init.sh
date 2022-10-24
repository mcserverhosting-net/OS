#!/bin/sh
set -e
echo Init success >> /tmp/log.txt

if ls -lah /dev/nvme0n1; then
  echo "Using an nvme." >> /tmp/log.txt
  export DISK=/dev/nvme0n1 
  sgdisk --zap-all $DISK
  blkdiscard $DISK
else
  echo "Using the first sata device." >> /tmp/log.txt
  export DISK=/dev/sda
  sgdisk --zap-all $DISK
  dd if=/dev/zero of="$DISK" bs=1M count=100 oflag=direct,dsync
fi


mkfs.ext4 $DISK
mount $DISK /mnt

systemctl enable --now crio 
export UUID=$(cat /sys/class/dmi/id/board_serial)
envsubst < /etc/kubeadm/kubeadm.conf.yaml | sponge /etc/kubeadm/kubeadm.conf.yaml
echo "mcsh-$UUID" > /etc/hostname
echo "127.0.0.1 mcsh-$UUID" > /etc/hosts
echo "::1 mcsh-$UUID" >> /etc/hosts


modprobe br_netfilter
modprobe ceph
echo '1' > /proc/sys/net/ipv4/ip_forward




kubeadm join --config /etc/kubeadm/kubeadm.conf.yaml
echo "Join operation complete." >> /tmp/log.txt