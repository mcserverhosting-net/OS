#!/bin/sh
if ls -lah /dev/nvme0n1; then
  echo "Using an nvme." >> /tmp/log.txt
  export DISK=/dev/nvme0n1 
  sgdisk --zap-all $DISK
  blkdiscard $DISK
elif ls -lah /dev/sda; then
  echo "Using the first sata device." >> /tmp/log.txt
  export DISK=/dev/sda
  sgdisk --zap-all $DISK
  dd if=/dev/zero of="$DISK" bs=1M count=100 oflag=direct,dsync
elif ls -lah /dev/vda; then
  echo "Using the first vda device." >> /tmp/log.txt
  export DISK=/dev/vda
  sgdisk --zap-all $DISK
  dd if=/dev/zero of="$DISK" bs=1M count=100 oflag=direct,dsync
else 
  echo "No disk device usable"
  exit 1
fi


mkfs.ext4 $DISK
mount $DISK /mnt

systemctl enable --now crio 
export UUID=$(cat /sys/class/net/$(ip route show default | awk '/default/ {print $5}')/address | sed s/://g )
mv /config/kubeadm/*.yaml /etc/kubeadm/kubeadm.conf.yaml
envsubst < /etc/kubeadm/kubeadm.conf.yaml | sponge /etc/kubeadm/kubeadm.conf.yaml
echo "home-$UUID" > /etc/hostname
echo "127.0.0.1 home-$UUID" > /etc/hosts
echo "::1 home-$UUID" >> /etc/hosts


modprobe br_netfilter
modprobe ceph
modprobe rbd
modprobe nbd


echo '1' > /proc/sys/net/ipv4/ip_forward

kubeadm join --config /etc/kubeadm/kubeadm.conf.yaml --v=5
echo "Join operation complete." >> /tmp/log.txt