#!/bin/sh
sudo podman run --privileged -v .:/profile registry.service.mcserverhosting.net/dev/archiso mkarchiso -v -w /tmp -o /profile/out /profile
