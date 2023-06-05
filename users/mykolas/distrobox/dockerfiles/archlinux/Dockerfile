#initial archlinux setup for distrobox

FROM archlinux:latest

USER root

#enable lib32
RUN echo "[multilib]" >> /etc/pacman.conf
RUN echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
RUN yes | pacman -Syu

RUN yes | pacman -S archlinux-keyring 
RUN yes | pacman-key --init
RUN yes | pacman-key --populate archlinux
RUN yes | pacman -Sy glibc lib32-glibc 

# base and base-devel
RUN pacman -S --noconfirm base base-devel
RUN yes | pacman -S git

#install nvidia drivers
RUN yes | pacman -S --needed nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader

#wine dependencies
RUN yes | pacman -S --needed wine-staging giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls \
mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error \
lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo \
sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libgcrypt libgcrypt lib32-libxinerama \
ncurses lib32-ncurses ocl-icd lib32-ocl-icd libxslt lib32-libxslt libva lib32-libva gtk3 \
lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader \
pipewire-jack wireplumber

RUN useradd -m build && usermod -L build
RUN cp /etc/sudoers /etc/sudoers.old
RUN echo "build ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN echo "root ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers


# #install AUR helper
# RUN su build
USER build
# RUN whoami
RUN git clone https://aur.archlinux.org/paru.git /home/build/paru
RUN cd /home/build/paru
RUN (cd /home/build/paru && makepkg -si --noconfirm) 
RUN rm -rf /home/build/paru
USER root


# #install other apps
RUN yes | pacman -S neovim python xorg-xhost helix telegram-desktop

# #install plasma
RUN yes | pacman -S plasma-desktop pipewire-jack wireplumber ttf-dejavu ttf-liberation phonon-qt5-vlc

#install fonts
RUN yes | pacman -S ttf-liberation noto-fonts ttf-dejavu
USER build
RUN yes | paru -S ttf-inconsolata-g
USER root

# #flatpak 
#RUN yes | pacman -S flatpak xdg-desktop-portal-kde xdg-desktop-portal

#bottles and lutris
#RUN pacman -S --noconfirm gamemode gvfs lib32-vkd3d lib32-vulkan-icd-loader vkd3d vulkan-icd-loader
#RUN pacman -S --noconfirm lutris
#USER build
#RUN paru -S --noconfirm bottles
# RUN paru -S --noconfirm latencyflex-git
#USER root

# install zsh
RUN yes | pacman -S zsh zsh-completions fzf

#update system
RUN pacman -Syu --noconfirm

#remove build user
RUN userdel build
RUN rm -rf /home/build
RUN mv /etc/sudoers.old /etc/sudoers




