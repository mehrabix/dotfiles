#!/bin/bash

# Check if stow is installed
if ! command -v stow &> /dev/null; then
    echo "GNU Stow is not installed. Please install it first."
    echo "On Debian/Ubuntu: sudo apt-get install stow"
    echo "On Arch Linux: sudo pacman -S stow"
    echo "On macOS: brew install stow"
    exit 1
fi

# Create necessary directories if they don't exist
mkdir -p ~/.config
mkdir -p ~/.oh-my-zsh
mkdir -p ~/.tmux/plugins

# Remove existing symlinks if they exist
rm -f ~/.tmux.conf
rm -f ~/.zshrc
rm -rf ~/.config/nvim
rm -rf ~/.oh-my-zsh
rm -rf ~/.tmux/plugins

# Use stow to create symlinks
echo "Restoring configurations..."
stow -t ~ nvim
stow -t ~ tmux
stow -t ~ zsh

# Install tmux plugins
echo "Installing tmux plugins..."
~/.tmux/plugins/tpm/bin/install_plugins

# Install Oh My Zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install Powerlevel10k theme if not already installed
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    echo "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
fi

echo "Configuration restored successfully!"
echo "Please restart your terminal or run 'source ~/.zshrc' to apply changes." 