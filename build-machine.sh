#!/bin/bash
# Debian 8 (jessie)
set -o xtrace
# Packages
apt-get update
apt-get dist-upgrade -y
apt-get install -y \
    cowsay git build-essential zsh htop iotop tmux rsync python-pip python3-pip \
    silversearcher-ag speedometer jq toilet wget curl apt-file pcregrep \
    emacs-nox emacs-goodies-el pv sudo locate python-dev python3-dev python3.4-venv \
    dnsutils tig
apt-file update
pip install virtualenv
pip install virtualenvwrapper
pip install ipython
pip3 install ipython

# Make my account
adduser liam --disabled-password --shell /usr/bin/zsh --gecos 'Liam Bowen'
mkdir -p /home/liam/.ssh
cp /root/.ssh/authorized_keys /home/liam/.ssh/authorized_keys
chown -R liam:liam /home/liam/.ssh
[[ ! -f /home/liam/.zshrc ]] && touch /home/liam/.zshrc
chown liam:liam /home/liam/.zshrc

# Sudo
[[ ! -f "/etc/sudoers.d/liam" ]] && echo 'liam ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/liam

# MongoDB repo
# Yes, this should say wheezy because at the time of writing they didn't have a jessie build
apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
echo 'deb http://repo.mongodb.org/apt/debian wheezy/mongodb-org/3.0 main' > /etc/apt/sources.list.d/mongodb-org-3.0.list
