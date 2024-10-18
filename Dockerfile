FROM archlinux

# Update and install necessary packages
RUN pacman -Syu --noconfirm archiso base-devel git sudo

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

# Switch back to root user if necessary
USER root

RUN gpg --recv-keys 0D4D2FDAF45468F3DDF59BEDE3D0D2CD3952E298
RUN rm -r /etc/pacman.d/gnupg/ && pacman-key --init && pacman-key --populate

# Continue with any other commands necessary for the archiso builder