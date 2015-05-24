#!/usr/bin/zsh
# Set up my regular user account
# Must be done interactively
cd

# SSH Key
ssh-keygen -t ecdsa -b 521 -N ''

# Upload key to Github
auth-json="$(printf '{"title":"%s","key":"%s"}\n' "cloud-$(date +%s)" "$(cat $HOME/.ssh/id_ecdsa.pub)")"
curl -u 'hut8' --data "${auth-json}" 'https://api.github.com/user/keys'

# Dotfiles except zsh
git clone git@github.com:hut8/dotfiles
./dotfiles/install

# Prezto
git clone --recursive git@github.com:hut8/prezto .zprezto
setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
  rm -f "${ZDOTDIR:-$HOME}/.${rcfile:t}"
  ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done
