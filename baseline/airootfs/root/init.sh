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
systemctl enable kubelet
echo "arch-$RANDOM" > /etc/hostname
kubeadm join --config /etc/kubeadm/kubeadm.conf.yaml
#kubeadm join nearest.ton618.one:6443 --token v1w7o8.w3rjbi1ezfderevp --discovery-token-ca-cert-hash sha256:d4c49500157420962b8a1287b9e23957c0e89b3095c7c50563ed1f21b5a61424
#kubeadm -v5 join nearest.ton618.one:6443 --token wfkspa.l8g8ngzzzrvasjkt --discovery-token-ca-cert-hash sha256:d4c49500157420962b8a1287b9e23957c0e89b3095c7c50563ed1f21b5a61424
echo "Join operation complete." >> /tmp/log.txt
