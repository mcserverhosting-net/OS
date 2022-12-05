#!/bin/sh

modprobe zram num_devices=1
echo 32G > /sys/block/zram0/disksize
export DISK=/dev/zram0

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