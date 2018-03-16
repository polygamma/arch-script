#!/bin/bash

# multilib
sudo sh -c "sed -i '/\[multilib\]/,/Include/s/^[ ]*#//' /etc/pacman.conf"
sudo pacman -Syy

# aurman
sudo pacman --needed --noconfirm -Syu git
git clone https://aur.archlinux.org/aurman-git.git
cd aurman-git/
makepkg -si --needed --noconfirm
cd ..
rm -rf aurman-git/

# makepkg
aurman --needed --noconfirm --noedit -Syu ccache
sudo sh -c "sed -i '/^[ ]*BUILDENV=/s/!ccache/ccache/' /etc/makepkg.conf"
grep "^[ ]*export PATH=\"/usr/lib/ccache/bin/:\$PATH\"" ~/.bashrc >/dev/null
if [ "$?" -eq 1 ]
then
    echo "export PATH=\"/usr/lib/ccache/bin/:\$PATH\"" >> ~/.bashrc
fi
sudo sh -c "sed -i '/MAKEFLAGS=/s/^.*$/MAKEFLAGS=\"-j\$(nproc)\"/' /etc/makepkg.conf"
sudo sh -c "sed -i '/PKGEXT=/s/^.*$/PKGEXT=\".pkg.tar\"/' /etc/makepkg.conf"

# mirrors
aurman --needed --noconfirm --noedit -Syu reflector
sudo reflector --save /etc/pacman.d/mirrorlist --sort rate --age 1 --country Germany --latest 10 --score 10 --number 5 --protocol http
sudo pacman --noconfirm -Syyu

# xorg + gnome
aurman --needed --noconfirm --noedit -Syu xorg-server gnome gdm networkmanager file-roller unrar plank gnome-tweak-tool
sudo systemctl enable gdm
sudo systemctl enable NetworkManager
gsettings set org.gnome.shell enabled-extensions "['user-theme@gnome-shell-extensions.gcampax.github.com']"
gsettings set org.gnome.desktop.peripherals.mouse accel-profile "flat"
gsettings set org.gnome.desktop.calendar show-weekdate true
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.interface clock-show-seconds true
gsettings set org.gnome.shell.overrides dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces "1"
gsettings set org.gnome.desktop.wm.preferences button-layout "appmenu:minimize,maximize,close"
gsettings set org.gnome.settings-daemon.plugins.xsettings overrides "{'Gtk/ShellShowsAppMenu': <0>}"
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'de')]"
gsettings set org.gnome.desktop.session idle-delay "0"
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type "nothing"
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type "nothing"
gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
gsettings set org.gnome.Terminal.Legacy.Settings new-terminal-mode "tab"
gsettings set org.gnome.Terminal.Legacy.Settings theme-variant "dark"
gsettings set org.gnome.nautilus.icon-view default-zoom-level "small"
gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled false
gsettings set org.gnome.desktop.peripherals.touchpad edge-scrolling-enabled true
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false
mkdir -p ~/.config/autostart
chmod 700 ~/.config
chmod 755 ~/.config/autostart
ln -sf /usr/share/applications/plank.desktop ~/.config/autostart/plank.desktop

# nvidia
aurman --needed --noconfirm --noedit -Syu nvidia-dkms lib32-nvidia-utils dkms linux-headers nvidia-settings

# intel
aurman --needed --noconfirm --noedit -Syu mesa lib32-mesa xf86-video-intel

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
aurman --needed --noconfirm --noedit -Syu libinput xf86-input-libinput xorg-xinput
sudo sh -c "echo 'Section \"InputClass\"
    Identifier \"My Mouse\"
    Driver \"libinput\"
    MatchIsPointer \"yes\"
    Option \"AccelProfile\" \"flat\"
EndSection' > /etc/X11/xorg.conf.d/50-mouse-acceleration.conf"

# nm-dispatcher-resolv.conf
aurman --needed --noconfirm --noedit -Syu git networkmanager-openvpn
git clone https://github.com/polygamma/nm-dispatcher-resolv.conf.git
cd nm-dispatcher-resolv.conf/
makepkg -si --needed --noconfirm
cd ..
rm -rf nm-dispatcher-resolv.conf/

# ufw
aurman --needed --noconfirm --noedit -Syu ufw
sudo ufw default deny
sudo ufw limit ssh
sudo ufw --force enable
sudo systemctl enable ufw

# time
sudo timedatectl set-ntp true

# ssh
aurman --needed --noconfirm --noedit -Syu wget openssh
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

# miscellaneous
aurman --needed --noconfirm --noedit -Syu bash-completion asp net-tools ntfs-3g android-tools android-udev dkms linux-headers ttf-google-fonts-git google-chrome woeusb-git jdk8-openjdk keepassx2 rsync dotpac downgrader openconnect networkmanager-openconnect filezilla intellij-idea-ultimate-edition intellij-idea-ultimate-edition-jre pycharm-professional clion clion-cmake clion-gdb clion-jre phpstorm phpstorm-jre android-studio gitkraken
sudo gpasswd -a $USER adbusers

# sublime
aurman --needed --noconfirm --noedit -Syu curl wget
curl -O https://download.sublimetext.com/sublimehq-pub.gpg && sudo pacman-key --add sublimehq-pub.gpg && sudo pacman-key --lsign-key 8A8F901A && rm sublimehq-pub.gpg
grep "\[sublime-text\]" /etc/pacman.conf >/dev/null
if [ "$?" -eq 1 ]
then
    echo -e "\n[sublime-text]\nServer = https://download.sublimetext.com/arch/stable/x86_64" | sudo tee -a /etc/pacman.conf
fi
sudo pacman -Syy
aurman --needed --noconfirm --noedit -Syu sublime-text
wget https://pastebin.com/raw/n64DScny
install -Dm700 n64DScny "$HOME/.config/sublime-text-3/Packages/User/Preferences.sublime-settings"
rm n64DScny

# themes
aurman --needed --noconfirm --noedit -Syu paper-icon-theme-git arc-gtk-theme
gsettings set org.gnome.shell.extensions.user-theme name "Arc"
gsettings set org.gnome.desktop.interface gtk-theme "Arc"
gsettings set org.gnome.desktop.interface icon-theme "Paper"
gsettings set org.gnome.desktop.interface cursor-theme "Paper"

# signal
aurman --needed --noconfirm --noedit -Syu signal-desktop-bin
