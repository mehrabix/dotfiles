#!/usr/bin/env bash
#
# Restore dotfiles on a fresh machine.
#
#   git clone https://github.com/mehrabix/dotfiles.git ~/.dotfiles
#   ~/.dotfiles/install.sh
#
# Idempotent: safe to re-run to pick up new changes.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(zsh nvim tmux bash git)
OMZ_DIR="$HOME/.oh-my-zsh"
OMZ_CUSTOM="$OMZ_DIR/custom"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

# --- 1. GNU Stow -------------------------------------------------------------
if ! command -v stow >/dev/null 2>&1; then
  info "GNU Stow not found, installing..."
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y stow
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y stow
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm stow
  elif command -v brew >/dev/null 2>&1; then
    brew install stow
  else
    die "Install GNU Stow manually, then re-run this script."
  fi
fi

# --- 2. Oh My Zsh ------------------------------------------------------------
if [[ ! -d "$OMZ_DIR" ]]; then
  info "Installing Oh My Zsh..."
  git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$OMZ_DIR"
else
  info "Oh My Zsh already installed."
fi

# --- 3. Custom plugins and theme --------------------------------------------
mkdir -p "$OMZ_CUSTOM/plugins" "$OMZ_CUSTOM/themes"

clone_or_pull() {
  local url="$1" dest="$2" name="${2##*/}"
  if [[ -d "$dest/.git" ]]; then
    info "Updating $name..."
    git -C "$dest" pull --ff-only --quiet || warn "Could not update $name."
  elif [[ -d "$dest" ]]; then
    info "$name present, leaving as is."
  else
    info "Installing $name..."
    git clone --depth 1 --quiet "$url" "$dest"
  fi
}

clone_or_pull https://github.com/romkatv/powerlevel10k.git            "$OMZ_CUSTOM/themes/powerlevel10k"
clone_or_pull https://github.com/zsh-users/zsh-autosuggestions.git    "$OMZ_CUSTOM/plugins/zsh-autosuggestions"
clone_or_pull https://github.com/zsh-users/zsh-syntax-highlighting.git "$OMZ_CUSTOM/plugins/zsh-syntax-highlighting"
clone_or_pull https://github.com/zsh-users/zsh-completions.git        "$OMZ_CUSTOM/plugins/zsh-completions"
clone_or_pull https://github.com/Aloxaf/fzf-tab.git                   "$OMZ_CUSTOM/plugins/fzf-tab"

command -v fzf >/dev/null 2>&1 || warn "fzf is not installed; fzf-tab will stay disabled."

# --- 4. Link the dotfiles ----------------------------------------------------
info "Linking packages with stow: ${PACKAGES[*]}"
cd "$DOTFILES_DIR"
# Ensure ~/.config exists so stow links ~/.config/nvim instead of folding the
# whole ~/.config directory into a single symlink.
mkdir -p "$HOME/.config"
if ! stow --target="$HOME" --restow "${PACKAGES[@]}"; then
  die "stow hit a conflict. Move the offending file aside and re-run."
fi

info "Done. Open a new shell to pick everything up."
