#!/bin/bash
set -e
echo Init success >> /tmp/log.txt

# Check if the other script exists
if test -f /boot/script; then
  # The other script exists, so run it
  sh /boot/script
fi


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
envsubst < /etc/kubeadm/kubeadm.conf.yaml | sponge /etc/kubeadm/kubeadm.conf.yaml
echo "home-$UUID" > /etc/hostname
echo "127.0.0.1 home-$UUID" > /etc/hosts
echo "::1 home-$UUID" >> /etc/hosts


modprobe br_netfilter
modprobe ceph
modprobe rbd
modprobe nbd
modprobe ip6_tables
modprobe ip_tables
modprobe ip6table_mangle
modprobe ip6table_raw
modprobe ip6table_filter
modprobe xt_socket


echo '1' > /proc/sys/net/ipv4/ip_forward

kubeadm join --config /etc/kubeadm/kubeadm.conf.yaml --v=5
echo "Join operation complete." >> /tmp/log.txt