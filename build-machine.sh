#!/bin/bash

# Rootly things
apt-get update
apt-get dist-upgrade
apt-get install -y \
    cowsay git build-essential zsh htop iotop tmux rsync python-pip python3-pip \
    silversearcher-ag speedometer jq toilet wget curl apt-file pcregrep \
    emacs-nox emacs-goodies-el
apt-file update
pip install virtualenv
pip install virtualenvwrapper

# Make my account
adduser liam --disabled-password --shell /usr/bin/zsh --gecos 'Liam'
mkdir -p /home/liam/.ssh
cp /root/.ssh/authorized_keys /home/liam/.ssh/authorized_keys
chown -R liam:liam /home/liam/.ssh
touch /home/liam/.zshrc
chown liam:liam /home/liam/.zshrc
