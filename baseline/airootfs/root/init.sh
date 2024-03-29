#!/bin/bash
set -e
echo Init success >> /tmp/log.txt
systemctl enable --now sshd

sleep 10s

# Define a list of candidate disks to use
candidate_disks="/dev/nvme0n1 /dev/sda /dev/vda"

# Function to check if a disk is empty (no partitions)
is_disk_empty() {
  local disk="$1"
  local partition_count

  # Get the number of partitions on the disk
  partition_count=$(parted --script "$disk" print | grep -c '^Number')

  # Check if there are no partitions
  [ "$partition_count" -eq 0 ]
}

# Function to wipe  and format a disk
wipe_and_format_disk() {
  local disk="$1"

  sgdisk --zap-all "$disk"
  if [ "$(basename "$disk")" = "nvme0n1" ]; then
    blkdiscard "$disk"
  else
    dd if=/dev/zero of="$disk" bs=1M count=100 oflag=direct,dsync
  fi

  mkfs.ext4 "$disk"
}

# Iterate through the candidate disks
for disk in $candidate_disks; do
  # Check if the disk exists
  if ls -lah "$disk" >/dev/null 2>&1; then
    # Check if the disk is empty
    if is_disk_empty "$disk"; then
      # Wipe and format the empty disk
      echo "Disk $disk is empty. Wiping and formatting it." >> /tmp/log.txt
      wipe_and_format_disk "$disk"
      export DISK="$disk"
      break
    else
      # Use the non-empty disk as a mount
      echo "Using non-empty disk $disk as a mount." >> /tmp/log.txt
      export DISK="$disk"
      break
    fi
  fi
done

# If no suitable disk was found, use a ramdisk
if [ -z "$DISK" ]; then
  echo "No disk device usable. Using a ramdisk. Assuming at least 16G of memory available." >> /tmp/log.txt
  #TODO: Use `grep MemTotal /proc/meminfo` and do either 16G or half of memory available, whichever is less.
  modprobe zram num_devices=1
  echo 16G > /sys/block/zram0/disksize
  export DISK=/dev/zram0
  mkfs.ext4 "$DISK"
fi

# Mount the disk to /mnt and /var/log
mount "$DISK" /mnt
mkdir /mnt/tmp

export UUID=$(cat /etc/machine-id)

envsubst < /etc/kubeadm/kubeadm.conf.yaml | sponge /etc/kubeadm/kubeadm.conf.yaml
echo "ephemeral-$UUID" > /etc/hostname
echo "127.0.0.1 ephemeral-$UUID" > /etc/hosts
echo "::1 ephemeral-$UUID" >> /etc/hosts

hostnamectl

systemctl restart avahi-daemon

#K8s options
modprobe br_netfilter
# Ceph options
# modprobe ceph
# modprobe rbd
# modprobe nbd

# Longhorn V1 options

# Longhorn V2 options
# modprobe uio
# modprobe uio_pci_generic
# modprobe nvme-tcp
# Note: Longhorn also needs hugepages


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
