#!/bin/sh
sudo podman run --privileged -v .:/profile registry.service.mcserverhosting.net/library/archiso:latest mkarchiso -v -w /tmp -o /profile/out /profile
