#!/bin/bash
set -e
echo "[INFO] Initializing the script. Enabling sshd service."
systemctl enable --now sshd

# Define a list of candidate disks to use
candidate_disks="/dev/nvme0n1 /dev/sda /dev/vda"

# Function to check if a disk is empty (no partitions)
is_disk_empty() {
  local disk="$1"
  echo "[INFO] Checking if $disk is empty."

  local partition_count
  partition_count=$(parted --script "$disk" print | grep -c '^Number')

  [ "$partition_count" -eq 0 ]
}

# Function to wipe  and format a disk
wipe_and_format_disk() {
  local disk="$1"
  echo "[INFO] Wiping and formatting disk: $disk."

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
      echo "[INFO] Disk $disk is empty. Proceeding to wipe and format it."
      wipe_and_format_disk "$disk"
      export DISK="$disk"
      break
    else
      echo "[INFO] Disk $disk is not empty. Using it as a mount."
      export DISK="$disk"
      break
    fi
  fi
done

# If no suitable disk was found, use a ramdisk
if [ -z "$DISK" ]; then
  echo "[WARN] No disk device found. Using a ramdisk. Assuming at least 32G of memory available."
  #TODO: Use `grep MemTotal /proc/meminfo` and do either 16G or half of memory available, whichever is less.
  modprobe zram num_devices=1
  echo 32G > /sys/block/zram0/disksize
  export DISK=/dev/zram0
  mkfs.ext4 "$DISK"
fi

# Mount the disk to /mnt and /var/log
mount "$DISK" /mnt
mkdir -p /mnt/tmp
mkdir -p /var/lib/kubelet
mount "$DISK" /var/lib/kubelet

echo "[INFO] Disk mounted to /mnt and /var/lib/kubelet"

export UUID=$(cat /etc/machine-id)

envsubst < /etc/kubeadm/kubeadm.conf.yaml | sponge /etc/kubeadm/kubeadm.conf.yaml
echo "ephemeral-$UUID" > /etc/hostname
echo "127.0.0.1 ephemeral-$UUID" > /etc/hosts
echo "::1 ephemeral-$UUID" >> /etc/hosts

hostnamectl

systemctl restart avahi-daemon

# Load Kernel modules for K8s, Ceph, Longhorn, and Cilium
echo "[INFO] Loading Kernel modules."

#K8s options
modprobe br_netfilter
# Ceph options
# modprobe ceph
# modprobe rbd
# modprobe nbd

# Longhorn V1 options
# modprobe iscsi_tcp

# Longhorn V2 options
# modprobe uio
# modprobe uio_pci_generic
# modprobe nvme-tcp
# Note: Longhorn also needs hugepages
# echo 1024 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages

#crio options
modprobe erofs

#Cilium ipv6 options (in nat mode)
modprobe ip6_tables
modprobe ip_tables
modprobe ip6table_mangle
modprobe ip6table_raw
modprobe ip6table_filter
modprobe xt_socket

echo '1' > /proc/sys/net/ipv4/ip_forward

systemctl enable --now iscsid
systemctl enable --now crio
systemctl enable --now kubelet
kubeadm join --config /etc/kubeadm/kubeadm.conf.yaml --v=5

echo "[INFO] Kubernetes join operation complete."