#!/bin/bash

# multilib
sudo sh -c "sed -i '/\[multilib\]/,/Include/s/^[ ]*#//' /etc/pacman.conf"
sudo pacman -Syy

# pacaur
sudo pacman --needed --noconfirm -Syu git
gpg --keyserver hkp://ipv4.pool.sks-keyservers.net:11371 --recv-keys 1EB2638FF56C0C53
git clone https://aur.archlinux.org/cower.git
cd cower/
makepkg -si --needed --noconfirm
cd ..
git clone https://aur.archlinux.org/pacaur.git
cd pacaur/
makepkg -si --needed --noconfirm
cd ..
sudo rm -r pacaur/
sudo rm -r cower/

# makepkg
pacaur --needed --noconfirm --noedit -Syu ccache
sudo sh -c "sed -i '/^[ ]*BUILDENV=/s/!ccache/ccache/' /etc/makepkg.conf"
grep "^[ ]*export PATH=\"/usr/lib/ccache/bin/:\$PATH\"" ~/.bashrc >/dev/null
if [ "$?" -eq 1 ]
then
    echo "export PATH=\"/usr/lib/ccache/bin/:\$PATH\"" >> ~/.bashrc
fi
sudo sh -c "sed -i '/MAKEFLAGS=/s/^.*$/MAKEFLAGS=\"-j\$(nproc)\"/' /etc/makepkg.conf"
sudo sh -c "sed -i '/PKGEXT=/s/^.*$/PKGEXT=\".pkg.tar\"/' /etc/makepkg.conf"

# mirrors
pacaur --needed --noconfirm --noedit -Syu reflector
sudo reflector --save /etc/pacman.d/mirrorlist --sort rate --age 1 --country Germany --latest 10 --score 10 --number 5 --protocol http
pacaur --noconfirm --noedit -Syyu

# xorg + gnome
pacaur --needed --noconfirm --noedit -Syu xorg-server gnome gdm networkmanager
sudo systemctl enable gdm
sudo systemctl enable NetworkManager

# nvidia
pacaur --needed --noconfirm --noedit -Syu nvidia-dkms lib32-nvidia-utils dkms linux-headers nvidia-settings

# intel
pacaur --needed --noconfirm --noedit -Syu mesa lib32-mesa xf86-video-intel

# disable ip_v6
interfaces=$(ip link | sed -n "/^[0-9]\+: \(ens\|eno\|enp\|wl\)[a-zA-Z0-9]\+:.*$/s/^[0-9]\+: \([a-zA-Z0-9]\+\):.*$/\1/p")
toecho="net.ipv6.conf.all.disable_ipv6 = 1\n"
for i in $interfaces; do
    toecho+="net.ipv6.conf.$i.disable_ipv6 = 1\n"
done
sudo sh -c "echo -e '$toecho' > /etc/sysctl.d/40-ipv6.conf"
sudo sh -c "sed -i 's/^[ ]*::1/#::1/' /etc/hosts"
sudo sh -c "sed -i 's/^[ ]*keyserver[ ]\+.*$/keyserver hkp:\/\/ipv4.pool.sks-keyservers.net:11371/' /etc/pacman.d/gnupg/gpg.conf"
grep "^[ ]*noipv6rs[ ]*$" /etc/dhcpcd.conf >/dev/null
if [ "$?" -eq 1 ]
then
    sudo sh -c "echo 'noipv6rs' >> /etc/dhcpcd.conf"
fi
grep "^[ ]*noipv6[ ]*$" /etc/dhcpcd.conf >/dev/null
if [ "$?" -eq 1 ]
then
    sudo sh -c "echo 'noipv6' >> /etc/dhcpcd.conf"
fi

# nano environment variable
grep "^[ ]*export EDITOR=\"/usr/bin/nano\"" ~/.bashrc >/dev/null
if [ "$?" -eq 1 ]
then
    echo "export EDITOR=\"/usr/bin/nano\"" >> ~/.bashrc
fi
sudo sh -c "grep '^[ ]*Defaults[ ]\+env_keep[ ]*+=[ ]*\"[ ]*EDITOR[ ]*\"' /etc/sudoers >/dev/null"
if [ "$?" -eq 1 ]
then
    echo 'Defaults env_keep += "EDITOR"' | sudo EDITOR='tee -a' visudo
fi

# mouse acceleration disabled with libinput
pacaur --needed --noconfirm --noedit -Syu libinput xf86-input-libinput xorg-xinput
sudo sh -c "echo 'Section \"InputClass\"
    Identifier \"My Mouse\"
    Driver \"libinput\"
    MatchIsPointer \"yes\"
    Option \"AccelProfile\" \"flat\"
EndSection' > /etc/X11/xorg.conf.d/50-mouse-acceleration.conf"

# nm-dispatcher-resolv.conf
pacaur --needed --noconfirm --noedit -Syu git networkmanager-openvpn
git clone https://github.com/polygamma/nm-dispatcher-resolv.conf.git
cd nm-dispatcher-resolv.conf/
makepkg -si --needed --noconfirm
cd ..
sudo rm -r nm-dispatcher-resolv.conf/

# ufw
pacaur --needed --noconfirm --noedit -Syu ufw
sudo ufw default deny
sudo ufw limit ssh
sudo ufw --force enable
sudo systemctl enable ufw

# time
sudo timedatectl set-ntp true

# ssh
pacaur --needed --noconfirm --noedit -Syu wget openssh
wget https://pastebin.com/raw/yD2g3ZXv
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cat yD2g3ZXv > ~/.ssh/authorized_keys
rm yD2g3ZXv
sudo sh -c "sed -i '/^[ ]*[#]*[ ]*PasswordAuthentication[ ]\+/s/^.*$/PasswordAuthentication no/' /etc/ssh/sshd_config"
sudo sh -c "sed -i '/^[ ]*[#]*[ ]*PermitRootLogin[ ]\+/s/^.*$/PermitRootLogin no/' /etc/ssh/sshd_config"
sudo systemctl enable sshd

# swapfile
grep "none[ ]\+swap[ ]\+defaults" /etc/fstab >/dev/null
if [ "$?" -eq 1 ]
then
    sudo fallocate -l 4G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    sudo sh -c "echo '/swapfile none swap defaults 0 0' >> /etc/fstab"
fi

# needed things
pacaur --needed --noconfirm --noedit -Syu bash-completion ntfs-3g android-tools android-udev file-roller unrar gnome-tweak-tool dkms linux-headers ttf-google-fonts-git google-chrome jdk keepassx2 rsync dotpac
sudo gpasswd -a $USER adbusers
