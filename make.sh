#!/bin/sh
set -e

#Make the ISO
sudo docker run --privileged -v ./baseline:/profile -v $PWD/customrepo:/customrepo -v /mnt/nfs:/profile/out harbor.home.sfxworks.net/library/archiso mkarchiso -v -w /tmp -o /profile/out /profile -quiet=y
