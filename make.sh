#!/bin/sh
set -e

#Make the ISO
sudo podman run --privileged --network=host -v ./baseline:/profile registry.service.mcserverhosting.net/library/archiso:latest mkarchiso -v -w /tmp -o /profile/out /profile -quiet=y
#Mount the ISO
sudo mkdir -p /mnt/iso
#Only the first will me mounted
sudo mount -o loop $PWD/baseline/out/* /mnt/iso

#Build the collection
empourus --loglevel=debug build collection . registry.service.mcserverhosting.net/dev/os:latest --dsconfig empourus/dataset.yaml

# Unmount the ISO
sudo umount /mnt/iso

#Push the collection
empourus --loglevel=debug push registry.service.mcserverhosting.net/dev/os:latest

