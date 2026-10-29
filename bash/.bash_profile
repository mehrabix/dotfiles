# ~/.bash_profile — managed by GNU Stow (.dotfiles/bash/.bash_profile)
#
# Arch (and Fedora) read ~/.bash_profile for login shells instead of
# ~/.profile, so this file exists to make the bash package work on both.
# ~/.profile is still shipped for Debian/Ubuntu, where it is the one used.

[[ -f ~/.bashrc ]] && . ~/.bashrc
