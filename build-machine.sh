#!/bin/bash
set -o xtrace

golang_uri='https://storage.googleapis.com/golang/go1.4.2.linux-amd64.tar.gz'

authorized_keys='
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCy9toABDl+MxzrmczVgkW6tdQtsFRMvd70jJTx1urY0t1UuU/JelQDRk4wkdu33X0Ykju5ddYzWNUq/jEKcxa8V1zJCnQWX/g/PytMItrlJ3M3Of4M5314H3cqIm2hpR7jEFJ4jFMjp3TGcb4khT9+jxHZBqjj6cIArtyVptAwxS+jycsZNgDIkw/Lt3y2uXq5M8MmNXff5EHQ2VDFOSN+fNvhml6BrrF/mfyzFj6M80huksSbc8uAwkd69UoEUWu4Ja0Uh1FR0V6pPesvxTPuuhhBK8xaEFefWK98vMrhCzWUT4yCQ58dbhtEGy8gEZBAIAzN3tsO9fiwyQY48Gi3 liam@raspberrypi
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDC6th7aMcuheMyuTmcVgjU8GSuAfbsLvviSzssM4XGgp7SFEPSZ7bOKcJrBWAJGqLx8pST5pgAnckbaRiCIoiqRIhGWMsHbH6c7PFyk1APygtqk3d5TibjkYpZm44DE5qOIhvpGG61VD3nNHbb1fF4Y0DoByTsmEHRR5sfyjeWH/M2G+vDJdza9QUU1EOu4hv7uNOp6RaUE5Ov70xnj2oewphOi+fMfnoUOCoAcJIcbVCqxLiElbw2ywEo3ZxKq2NyNoaSYWCCBTZPwVcV82EVu0WijOzXH7YDszHaoczQ0s7H0+rcbUq2XWBAiYi0yCsDxmYcBbo1bsMGUL3SdJP/ liam@turing
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDW76NxR6k4c1XqFWIi3n4Z4IKXNI1gwlaHmZGbcnrfNfFKjqR1uyJzEMs4YF0WXI+Z1YKa2c3wQgKKM+gcvz+4mCnu28iywRltnXyk1SN7SZp+C0UMwgv9ZkMyhxtyFXGRj6HJd8wYR5xXulD4UXqFgvplvWeqn35Dcf13TndwmnB41kq43jG3LfczqJCE6LtBdPgYco29UvRxIPQMRCT6Jz8zHfqmQMJXT82dOmzN9QMfE/CC4OI5Nz/NMFR9N9A6yG8zJTkaISm5DTB7k6LU1pB4/lCXlGkh+qWVg9mKaDFkpwuEgD0iOetRamFbrkV7asorFFcjJKu4ouo945Rx sandbox@turing
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDW9UYX1YXIVAX0IvO5JaInPzWKaffJeGBIgB3rWWT15rP0tsQEQ0y2Ys3DLgOwPEcn/DqAWP5PNNkVc1/HzOgRMZ13+1lIW12962NqGRUK3ByM5j5e/UmRYFRawzou+t9lHmbM6BrI0pyU+IbchKx8gwxagl2D9EuPapHdhMc7pv21YWUuEwxmMsPVudIS1iOzKtsGZIxpvXY5dq89MpDd4w3XN4ip6nCv2rMwzAo73YUYOw/Yc0zkWvmoJdTBJ+ldb+NW/QgkqAR3iWZ0UY0MBX4tMZMyzgKaw+0ayX9/jBbQoaqanB4Oj4/FTdATHgWx6dc+PXe/vqkeZmBVzGuT liam@vultr.guest
ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAmmejr3BwzboyLafUAD0hgF+YHxPZKa1bHAW6b6dZKxGLEKOikvGhBc6Zx38nGNWpwUHQIlnUAURZRr/KkNT3MkLY18Kjn1NRQ2CvMBFxwVNlY7NZCmOapRKCvKzk+b42qal43lmdXVvrf4hocPCF2OsHgZ2G4IuVoYrd/MOhwS8= rsa-key-20110323
'

debian() {
    echo 'Building for Debian Jessie'
    local packages='cowsay git build-essential zsh htop iotop tmux rsync python-pip'
    packages+='python3-pip silversearcher-ag speedometer jq toilet wget curl apt-file'
    packages+='pcregrep emacs-nox emacs-goodies-el pv sudo locate python-dev'
    packages+='python3-dev python3.4-venv dnsutils tig'
    # Debian 8 (jessie)
    apt-get update
    apt-get dist-upgrade -y
    apt-get install -y ${packages}
    apt-file update
    pip install virtualenv
    pip install virtualenvwrapper
    pip install ipython
    pip3 install ipython

    # Install Go
    curl $golang_uri | tar -C /usr/local -xvf

    # MongoDB
    # Yes, this should say wheezy; they didn't have a jessie build
    apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
    mongodb_repo='deb http://repo.mongodb.org/apt/debian wheezy/mongodb-org/3.0 main'
    echo "${mongodb_repo}" > /etc/apt/sources.list.d/mongodb-org-3.0.list

    # Make my account
    adduser liam --disabled-password --shell /usr/bin/zsh --gecos 'Liam Bowen'
}

arch() {
    echo "Building for Arch"
    local packages="cowsay git zsh htop iotop tmux rsync python-pip"
    packages+="the_silver_searcher jq figlet wget curl emacs-nox pv mlocate"
    packages+="dnsutils tig go mercurial"
    pacman -Syu
    pacman -S --noconfirm ${packages}
    pip install --upgrade pip
    pip install virtualenv
    pip install virtualenvwrapper

    # Make my account
    useradd -m -G wheel -s /usr/bin/zsh liam
}

common() {
    echo "Building common stuff"

    # Sudo
    if [[ ! -f "/etc/sudoers.d/liam" ]];
    then
        echo 'liam ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/liam
    fi

    # ssh key stuff
    mkdir -p /root/.ssh
    if [[ ! -f /root/.ssh/authorized_keys ]];
    then
        echo "${authorized_keys}" >> /root/.ssh/authorized_keys
    fi
    mkdir -p /home/liam/.ssh
    if [[ ! -f /home/liam/.ssh/authorized_keys ]];
    then
        echo "${authorized_keys}" >> /home/liam/.ssh/authorized_keys
    fi

    # this shuts up zsh the first time I start it:
    [[ ! -f /home/liam/.zshrc ]] && touch /home/liam/.zshrc

    # fix permissions
    chown -R liam:liam /home/liam/
}

is_debian() {
    local distro="$(lsb_release --short --id)"
    [[ $distro == "Debian" ]]
    return $?
}

is_arch() {
    local uname_r="$(uname -r)"
    [[ $uname_r =~ 'ARCH' ]]
    return $?
}

is_debian && debian
is_arch && arch
common
