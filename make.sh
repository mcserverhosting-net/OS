#!/bin/sh
set -e

#Make the ISO
sudo podman run --privileged -v ./baseline:/profile -v $PWD/customrepo:/customrepo registry.service.mcserverhosting.net/library/archiso:latest mkarchiso -v -w /tmp -o /profile/out /profile -quiet=y
