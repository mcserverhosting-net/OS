#!/bin/sh
set -e

#Make the ISO
sudo podman run --privileged -v ./baseline:/profile registry.service.mcserverhosting.net/library/archiso:latest mkarchiso -v -w /tmp -o /profile/out /profile -quiet=y
#Mount the ISO
#Only the first will me mounted
sudo mount -o loop $PWD/baseline/out/* $PWD/empourus/boot

#Build the collection
empourus --loglevel=debug build collection empourus registry.service.mcserverhosting.net/dev/os:latest --dsconfig empourus/dataset.yaml

# Unmount the ISO
sudo umount $PWD/empourus/boot

#Push the collection
empourus --loglevel=debug push registry.service.mcserverhosting.net/dev/os:latest

