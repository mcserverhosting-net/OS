FROM archlinux

# Update and install necessary packages
RUN pacman -Syu --noconfirm archiso base-devel git sudo wget grub edk2-shell gettext

# Create a non-root user to use yay (AUR helper does not allow root)
RUN useradd -m user \
    && echo "user ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/user

USER user
WORKDIR /home/user

# Install yay
RUN git clone https://aur.archlinux.org/yay.git \
    && cd yay \
    && makepkg -si --noconfirm

# Install AUR packages
RUN yay -S --noconfirm alhp-keyring alhp-mirrorlist

USER root

# Set the entrypoint (optional)
ENTRYPOINT ["mkarchiso"]
