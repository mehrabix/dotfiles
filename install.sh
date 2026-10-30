#!/usr/bin/env bash
#
# Restore this whole machine from the repo in one run: packages, every
# dotfile (stowed), Oh My Zsh + plugins, GNOME/dconf settings, the Dracula glass
# theme and the system tweaks.
#
#   git clone https://github.com/mehrabix/dotfiles.git ~/.dotfiles
#   ~/.dotfiles/install.sh
#
# Idempotent: safe to re-run to pick up new changes. To capture changes made on
# this machine back into the repo, run ./sync.sh first.
#
# Options:
#   --no-packages   don't install zsh/tmux/nvim/... (assume they are present)
#   --no-shell      leave the login shell alone
#   --no-tweaks     skip the system tweaks (plymouth, swappiness, cups, sudo)
#   --no-dconf      don't import the GNOME/dconf settings
#   --no-desktop    don't install the Dracula theme/icons/cursor/extensions
#   --help

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(bash config git nvim ptyxis tmux zsh)
OMZ_DIR="$HOME/.oh-my-zsh"
OMZ_CUSTOM="$OMZ_DIR/custom"

INSTALL_PACKAGES=true
SET_SHELL=true
APPLY_TWEAKS=true
IMPORT_DCONF=true
INSTALL_DESKTOP=true

for arg in "$@"; do
  case "$arg" in
    --no-packages) INSTALL_PACKAGES=false ;;
    --no-shell)    SET_SHELL=false ;;
    --no-tweaks)   APPLY_TWEAKS=false ;;
    --no-dconf)    IMPORT_DCONF=false ;;
    --no-desktop)  INSTALL_DESKTOP=false ;;
    --help)        sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) printf 'unknown option: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

# --- 0. Platform -------------------------------------------------------------
PM=""
for candidate in pacman apt-get dnf brew; do
  command -v "$candidate" >/dev/null 2>&1 && { PM="$candidate"; break; }
done

run_root() {
  if [[ $EUID -eq 0 ]]; then "$@"
  elif command -v sudo >/dev/null 2>&1; then sudo "$@"
  else die "Root is required for: $* (install sudo or run as root)."
  fi
}

install_packages() {
  case "$PM" in
    pacman) run_root pacman -S --needed --noconfirm "$@" ;;
    apt-get) run_root apt-get update -qq && run_root apt-get install -y "$@" ;;
    dnf) run_root dnf install -y "$@" ;;
    brew) brew install "$@" ;;
    *) die "No supported package manager found; install manually: $*" ;;
  esac
}

# --- 1. Packages -------------------------------------------------------------
# The scripts assume these exist; installing them here is what makes a fresh
# Arch/Fedora install work without hunting for names (fd vs fdfind, 7zip vs
# p7zip, github-cli vs gh, ...).
if [[ "$INSTALL_PACKAGES" == true ]]; then
  missing=()
  for tool in stow zsh tmux nvim fzf rg node npm gh wl-copy ptyxis dconf curl unzip gjs python3; do
    command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
  done
  # Needed to build Treesitter parsers on first Neovim launch.
  command -v tree-sitter >/dev/null 2>&1 || missing+=(tree-sitter-cli)
  command -v lesspipe >/dev/null 2>&1 || command -v lesspipe.sh >/dev/null 2>&1 || missing+=(lesspipe)
  command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1 || missing+=(fd)
  command -v make >/dev/null 2>&1 || missing+=(make)

  if ((${#missing[@]})); then
    info "Missing tools: ${missing[*]}"
    case "$PM" in
      pacman)
        install_packages stow zsh tmux neovim fzf fd nodejs npm ripgrep \
          github-cli wl-clipboard lesspipe bash-completion ptyxis make \
          tree-sitter-cli dconf curl tar unzip gjs glib2 python
        ;;
      apt-get)
        install_packages stow zsh tmux neovim fzf fd-find nodejs npm ripgrep \
          gh wl-clipboard lesspipe bash-completion make \
          dconf-cli curl tar unzip gjs libglib2.0-bin python3
        # Needed for Treesitter; not packaged on every release.
        run_root apt-get install -y tree-sitter-cli >/dev/null 2>&1 \
          || warn "tree-sitter-cli is not packaged here; install it from npm (npm i -g tree-sitter-cli)."
        # Ptyxis only exists on Ubuntu 25.04+; not worth failing the run over.
        run_root apt-get install -y ptyxis >/dev/null 2>&1 \
          || warn "Ptyxis is not packaged here; skipping the terminal profile."
        ;;
      dnf)
        install_packages stow zsh tmux neovim fzf fd-find nodejs npm ripgrep \
          gh wl-clipboard lesspipe bash-completion make \
          dconf curl tar unzip gjs glib2 python3
        run_root dnf install -y tree-sitter-cli >/dev/null 2>&1 \
          || warn "tree-sitter-cli is not packaged here; install it from npm (npm i -g tree-sitter-cli)."
        ;;
      brew)
        install_packages stow zsh tmux neovim fzf fd node npm ripgrep gh make
        ;;
      *)
        warn "Unknown package manager; install manually: ${missing[*]}"
        ;;
    esac
  else
    info "Dependencies already installed."
  fi

  # --- 1b. Gaming stack ------------------------------------------------------
  # Only on Arch: these names differ everywhere else, and Steam itself is a
  # personal choice, so it is not installed here. GameMode + MangoHud and both
  # Vulkan drivers (64- and 32-bit) are what game-run/.local/bin relies on.
  if [[ "$PM" == pacman ]] && command -v steam >/dev/null 2>&1; then
    gaming=(gamemode mangohud vulkan-radeon vulkan-intel)
    # 32-bit driver stack, for 32-bit games and Steam's own helper processes.
    if pacman -Si lib32-vulkan-radeon >/dev/null 2>&1; then
      gaming+=(lib32-vulkan-radeon lib32-vulkan-intel lib32-gamemode lib32-mangohud)
    fi
    missing_gaming=()
    for pkg in "${gaming[@]}"; do
      pacman -Qq "$pkg" >/dev/null 2>&1 || missing_gaming+=("$pkg")
    done
    if ((${#missing_gaming[@]})); then
      info "Missing gaming packages: ${missing_gaming[*]}"
      install_packages "${missing_gaming[@]}"
    else
      info "Gaming packages already installed."
    fi
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
mkdir -p "$HOME/.config" "$HOME/.local/bin"
if ! stow --target="$HOME" --restow "${PACKAGES[@]}"; then
  die "stow hit a conflict. Move the offending file aside and re-run."
fi

# --- 5. GNOME settings -------------------------------------------------------
# dconf is not a file, so it cannot be stowed: replay the dump captured by
# sync.sh. Extensions/theme keys land even when their schema is not installed
# yet; they take effect once the desktop step or a login loads them.
if [[ "$IMPORT_DCONF" == true ]] && command -v dconf >/dev/null 2>&1; then
  if [[ -s "$DOTFILES_DIR/dconf/gnome.ini" ]]; then
    info "Restoring GNOME settings from dconf/gnome.ini..."
    dconf load /org/gnome/ < "$DOTFILES_DIR/dconf/gnome.ini"
  else
    warn "dconf/gnome.ini is empty; keeping the current GNOME settings."
  fi
fi

# --- 6. Desktop look ---------------------------------------------------------
# Theme, icons, cursor, fonts, wallpapers, extensions and the power menu. The
# script is user-level; it only needs sudo for --with-sudo (GDM) and --gdm-only.
if [[ "$INSTALL_DESKTOP" == true ]]; then
  if [[ -x "$DOTFILES_DIR/dracula-desktop/setup.sh" ]]; then
    info "Installing the desktop look (Dracula + glass)..."
    "$DOTFILES_DIR/dracula-desktop/setup.sh" \
      || warn "The desktop setup did not finish; re-run it by hand for details."
  else
    warn "dracula-desktop/setup.sh is missing; skipping the desktop look."
  fi
fi

# --- 7. Login shell ----------------------------------------------------------
if [[ "$SET_SHELL" == true ]] && command -v zsh >/dev/null 2>&1; then
  zsh_path="$(command -v zsh)"
  current_shell="$(getent passwd "${USER}" | cut -d: -f7 || true)"
  if [[ "$current_shell" == "$zsh_path" ]]; then
    info "Login shell is already zsh."
  else
    info "Setting the login shell to $zsh_path..."
    run_root chsh -s "$zsh_path" "${USER}" \
      || warn "Could not change the login shell; run: chsh -s $zsh_path"
  fi
fi

# --- 8. Terminal (Ptyxis) ----------------------------------------------------
# The palette lives in the stow package; these settings live in dconf, so they
# cannot be symlinked and must be applied with gsettings. Values mirror macOS
# Terminal: login shell, bold-is-bright, block cursor.
if command -v ptyxis >/dev/null 2>&1 && gsettings list-schemas 2>/dev/null | grep -x 'org.gnome.Ptyxis' >/dev/null; then
  info "Configuring Ptyxis (macOS-style dark terminal)..."
  gsettings set org.gnome.Ptyxis interface-style 'dark' 2>/dev/null || true
  gsettings set org.gnome.Ptyxis use-system-font false 2>/dev/null || true
  gsettings set org.gnome.Ptyxis font-name 'SF Mono 12' 2>/dev/null || true
  gsettings set org.gnome.Ptyxis cursor-shape 'block' 2>/dev/null || true
  gsettings set org.gnome.Ptyxis cursor-blink-mode 'system' 2>/dev/null || true
  gsettings set org.gnome.Ptyxis disable-padding false 2>/dev/null || true

  profile_uuid="$(gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'")" || true
  # An empty array comes back as `@as []`; there is no profile until ptyxis has
  # been launched at least once.
  [[ "${profile_uuid:-}" == "@as []" || "${profile_uuid:-}" == "[]" ]] && profile_uuid=""
  if [[ -z "${profile_uuid:-}" ]]; then
    profile_uuid="$(gsettings get org.gnome.Ptyxis profile-uuids 2>/dev/null \
      | grep -oE '[0-9a-f]{16,}' | head -1)" || true
  fi
  if [[ -n "${profile_uuid:-}" ]]; then
    profile="org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${profile_uuid}/"
    gsettings set "$profile" palette 'macOS' 2>/dev/null || true
    gsettings set "$profile" login-shell true 2>/dev/null || true
    gsettings set "$profile" bold-is-bright true 2>/dev/null || true
    gsettings set "$profile" opacity 0.85 2>/dev/null || true
  else
    warn "Ptyxis has no profile yet; launch it once and re-run for the palette."
  fi

  # Note: no `grep -q` here — it exits early and, under `pipefail`, fc-list's
  # SIGPIPE makes the pipeline look like a failure (false "not installed").
  if ! fc-list 2>/dev/null | grep -i 'SF Mono' >/dev/null; then
    warn "SF Mono is not installed; the terminal will fall back to another font."
    warn "See the README for how to install it."
  fi
else
  warn "Ptyxis not installed; skipping the terminal theme."
fi

# --- 9. Editor prerequisites -------------------------------------------------
# The first `nvim` launch installs lazy.nvim plugins, Treesitter parsers and
# Mason tools; that needs a network connection and these tools on PATH. Missing
# ones only warn -- the editor still opens.
missing=()
for tool in git fzf rg node npm make tree-sitter; do
  command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
done
if ((${#missing[@]})); then
  warn "Missing tools used by Neovim: ${missing[*]}"
  warn "ripgrep (rg) powers Telescope's grep; node/npm power Mason's installs;"
  warn "tree-sitter builds the Treesitter parsers on first launch."
fi

# --- 10. System tweaks --------------------------------------------------------
unit_exists()      { systemctl list-unit-files --no-legend "$1" 2>/dev/null | grep . >/dev/null; }
user_unit_exists() { systemctl --user list-unit-files --no-legend "$1" 2>/dev/null | grep . >/dev/null; }

if [[ "$APPLY_TWEAKS" == true ]]; then
  # Ubuntu's crash notifier costs ~5s of session startup and we don't need it.
  # Reversible with `systemctl --user unmask <unit>`.
  for unit in update-notifier-crash.service update-notifier-crash.path; do
    user_unit_exists "$unit" && systemctl --user mask "$unit" >/dev/null 2>&1 || true
  done

  # Plymouth's splash keeps multi-user.target waiting ~7s on a machine without
  # disk encryption. Undo: sudo systemctl unmask plymouth-quit-wait.service
  unit_exists plymouth-quit-wait.service \
    && run_root systemctl mask plymouth-quit-wait.service >/dev/null 2>&1 || true

  # Keep swap use low on an SSD. Undo: remove the file, then `sudo sysctl --system`.
  if [[ ! -e /etc/sysctl.d/99-swappiness.conf ]]; then
    echo 'vm.swappiness=10' | run_root tee /etc/sysctl.d/99-swappiness.conf >/dev/null || true
  fi
  run_root sysctl --system >/dev/null 2>&1 || true

  # Services this laptop does not use: printing, mobile broadband, dual-GPU
  # switching and crash dumps. Re-enable any with `sudo systemctl enable --now`.
  # Only touch units that actually exist on this distro.
  for unit in cups.service cups.socket cups-browsed.service ModemManager.service \
              switcheroo-control.service kdump-tools.service; do
    unit_exists "$unit" || continue
    run_root systemctl disable --now "$unit" >/dev/null 2>&1 || true
  done

  # sudo-rs (Debian/Ubuntu) echoes a `*` per keystroke by default; restore
  # silent password entry. Plain sudo already does this. Undo: sudo rm
  # /etc/sudoers.d/0pwfeedback
  if sudo -V 2>/dev/null | grep -i 'sudo-rs' >/dev/null && [[ ! -e /etc/sudoers.d/0pwfeedback ]]; then
    printf 'Defaults !pwfeedback\n' | run_root tee /etc/sudoers.d/0pwfeedback >/dev/null
    run_root chmod 0440 /etc/sudoers.d/0pwfeedback
  fi
fi

info "Done. Open a new shell to pick everything up."
