#!/usr/bin/env bash
#
# sync.sh — copy this machine's live config into the dotfiles repo.
#
# The repo is the source of truth for a machine (install.sh puts it back), so
# run this after changing a config by hand:
#
#   ~/.dotfiles/sync.sh            # update the repo in place
#   cd ~/.dotfiles && git diff     # review, then commit/push
#
# Only non-sensitive configuration is copied. Secrets, browser profiles,
# keyrings, caches, logs, session state and app tokens are excluded.
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$DOTFILES_DIR/config"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }

# Paths (relative to $HOME) mirrored into config/. Add new configs here and
# install.sh will link them on the next restore.
PATHS=(
  .npmrc
  .local/bin/game-run
  .local/bin/gnome-theme-switcher
  .config/alacritty
  .config/background
  .config/btop/btop.conf
  .config/cava
  .config/chrome-flags.conf
  .config/chromium-flags.conf
  .config/equibop/settings/settings.json
  .config/fastfetch/config.jsonc
  .config/fish
  .config/gamemode.ini
  .config/ghostty
  .config/gtk-3.0/bookmarks
  .config/kdeglobals
  .config/kitty
  .config/mimeapps.list
  .config/monitors.xml
  .config/neofetch/config.conf
  .config/pavucontrol.ini
  .config/pip/pip.conf
  .config/qt6ct/qt6ct.conf
  .config/starship.toml
  .config/starship/layouts
  .config/systemd/user/voxtype.service
  .config/user-dirs.dirs
  .config/user-dirs.locale
  .config/vesktop/settings/settings.json
  .config/vlc/vlcrc
  .config/wireplumber/wireplumber.conf.d/51-bluetooth-codecs.conf
  .config/yazi
  .config/zathura
)

# --- 1. Configuration files --------------------------------------------------
# Stage everything first: the live files are Stow symlinks into this same repo,
# so deleting the repo copy before reading would leave dangling links.
info "Copying configuration into $DEST"
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
for path in "${PATHS[@]}"; do
  if [[ ! -e "$HOME/$path" && ! -L "$HOME/$path" ]]; then
    warn "$path does not exist here, skipping"
    continue
  fi
  # -L: read through the Stow symlink instead of copying the link itself.
  mkdir -p "$stage/$(dirname "$path")"
  cp -aL "$HOME/$path" "$stage/$path"
  printf '    %s\n' "$path"
done
rm -rf "$DEST"
mv "$stage" "$DEST"
trap - EXIT
chmod +x "$DEST/.local/bin/gnome-theme-switcher" "$DEST/.local/bin/game-run" 2>/dev/null || true

# --- 2. GNOME settings -------------------------------------------------------
# dconf holds the desktop settings (theme, extensions, keybindings, wallpaper,
# monitor layout). Per-network EAP state, recent-file lists and per-app
# notification history are dropped: they are machine state, not config.
if command -v dconf >/dev/null 2>&1; then
  info "Exporting GNOME settings to dconf/gnome.ini"
  mkdir -p "$DOTFILES_DIR/dconf"
  filter="$(mktemp)"
  cat >"$filter" <<'PY'
import re, sys
drop = ("nm-applet", "portal/filechooser", "calculator", "clocks/state", "Console",
        "epiphany", "gnome-system-monitor", "maps", "nautilus/window-state",
        "desktop/notifications/application")
out, keep = [], True
for line in sys.stdin.read().splitlines():
    if line.startswith("["):
        keep = not any(line.strip("[]").startswith(d) for d in drop)
    if keep:
        out.append(line)
new = re.sub(r"\n{3,}", "\n\n", "\n".join(out).strip()) + "\n"
open(sys.argv[1], "w").write(new)
PY
  dconf dump /org/gnome/ | python3 "$filter" "$DOTFILES_DIR/dconf/gnome.ini"
  rm -f "$filter"
else
  warn "dconf is not installed; skipping the GNOME settings export"
fi

# --- 3. Report ---------------------------------------------------------------
info "Synced. Review and commit:"
git -C "$DOTFILES_DIR" status --short
