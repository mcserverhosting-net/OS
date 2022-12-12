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
  echo "No disk device usable. Using a ramdisk. Assuming at least 16G of memory availible."
  #TODO: Use `grep MemTotal /proc/meminfo` and do either 16G or half of memory availbile, whichever is less. 
  modprobe zram num_devices=1
  echo 16G > /sys/block/zram0/disksize
  export DISK=/dev/zram0
fi

mkfs.ext4 $DISK
mount $DISK /mnt
mount $DISK /var/log
mkdir /mnt/tmp

export UUID=$(cat /sys/class/net/$(ip route show default | awk '/default/ {print $5}')/address | sed s/://g )

#Gateway IP to get kubeadm config by default
export GW_IP=$(ip route | awk '/default/ { print $3 }')
curl -LO "http://$GW_IP/kubeadm.conf.yaml"

cp kubeadm.conf.yaml /etc/kubeadm/kubeadm.conf.yaml
envsubst < /etc/kubeadm/kubeadm.conf.yaml | sponge /etc/kubeadm/kubeadm.conf.yaml
echo "mcsh-$UUID" > /etc/hostname
echo "127.0.0.1 mcsh-$UUID" > /etc/hosts
echo "::1 mcsh-$UUID" >> /etc/hosts


#K8s options
modprobe br_netfilter
#Ceph options
modprobe ceph
modprobe rbd
modprobe nbd
#Cilium ipv6 options (in nat mode)
modprobe ip6_tables
modprobe ip_tables
modprobe ip6table_mangle
modprobe ip6table_raw
modprobe ip6table_filter
modprobe xt_socket

echo '1' > /proc/sys/net/ipv4/ip_forward

systemctl enable --now crio 
kubeadm join --config /etc/kubeadm/kubeadm.conf.yaml --v=5
echo "Join operation complete." >> /tmp/log.txt