#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="archlinux-baseline"
iso_label="ARCH_$(date +%Y%m)"
iso_publisher="MC Server Hosting LLC <https://mcserverhosting.net>"
iso_application="Arch Linux baseline"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito'
           'uefi-ia32.grub.esp' 'uefi-x64.grub.esp'
           'uefi-ia32.grub.eltorito' 'uefi-x64.grub.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
#airootfs_image_tool_options=('-b 1M' '-comp xz')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root/init.sh"]="0:0:755"
  ["/root/.ssh"]="0:0:700"
)
