#!/bin/bash

# Check if disk is empty
function is_disk_empty() {
  local disk="$1"
  local disk_content=$(ls "$disk")
  if [ -z "$disk_content" ]; then
    return 0
  else
    return 1
  fi
}

# Wipe and format disk
function wipe_and_format_disk() {
  local disk="$1"
  wipefs --all "$disk"
  mkfs.ext4 "$disk"
}

# List of candidate disks
candidate_disks=(/dev/sda /dev/sdb /dev/sdc /dev/sdd)

# Iterate through candidate disks
for disk in "${candidate_disks[@]}"; do
  # Check if disk exists
  if [ -b "$disk" ]; then
    # Check if disk is empty
    if is_disk_empty "$disk"; then
      # Wipe and format disk
      wipe_and_format_disk "$disk"
    fi
    # Use disk as mount
    mount "$disk" /mnt
    break
  fi
done

# Create temporary directory
mkdir -p /tmp/kubernetes

# Export UUID and Gateway IP
export UUID=$(blkid -s UUID -o value /dev/sda1)
export GATEWAY_IP=192.168.1.1

# Update hostname and hosts files
echo "k8s-node-$(uuidgen | cut -c-5)" > /etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts

# Load necessary modules
modprobe overlay
modprobe br_netfilter

# Enable IP forwarding
sysctl net.ipv4.ip_forward=1

# Start crio service
systemctl start crio

# Install kubeadm using pacman
pacman -Syu kubeadm

# Join Kubernetes cluster
kubeadm join --config /etc/kubeadm/types.go