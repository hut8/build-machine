#!/bin/bash
# Debian 8 (jessie)

# Packages
apt-get update
apt-get dist-upgrade -y
apt-get install -y \
    cowsay git build-essential zsh htop iotop tmux rsync python-pip python3-pip \
    silversearcher-ag speedometer jq toilet wget curl apt-file pcregrep \
    emacs-nox emacs-goodies-el pv sudo locate
apt-file update
pip install virtualenv
pip install virtualenvwrapper
pip install ipython
pip3 install ipython

# Make my account
adduser liam --disabled-password --shell /usr/bin/zsh --gecos 'Liam'
mkdir -p /home/liam/.ssh
cp /root/.ssh/authorized_keys /home/liam/.ssh/authorized_keys
chown -R liam:liam /home/liam/.ssh
[[ ! -f /home/liam/.zshrc ]] && touch /home/liam/.zshrc
chown liam:liam /home/liam/.zshrc

# Sudo
[[ ! -f "/etc/sudoers.d/liam" ]] && echo 'liam ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/liam

# Mail me
# TODO
