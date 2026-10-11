#!/usr/bin/env bash
#
# macos-desktop/setup.sh — make Ubuntu / GNOME Shell look like macOS.
#
# Everything user-level lands in $HOME (themes, icons, cursors, fonts,
# extensions, wallpaper) and is applied with gsettings. Two things need root:
# the theme build dependencies (sassc, imagemagick, ...) and the GDM login
# screen theme. Both are opt-in.
#
#   ./macos-desktop/setup.sh                 user-level only
#   ./macos-desktop/setup.sh --with-sudo     + apt build deps + GDM theme
#   ./macos-desktop/setup.sh --gdm-only      only the GDM login screen theme
#
set -euo pipefail

# ── Config ─────────────────────────────────────────────────────
ACCENT="${ACCENT:-blue}"
GTK_THEME="WhiteSur-Dark-solid-${ACCENT}"   # solid variant (no transparency)
SHELL_THEME="WhiteSur-Dark-${ACCENT}"
ICON_THEME="WhiteSur-dark"
CURSOR_THEME="WhiteSur-cursors"
WALLPAPER="Sonoma-dark.jpg"

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/macos-desktop"
THEMES="$HOME/.themes"
ICONS="$HOME/.local/share/icons"
FONTS="$HOME/.local/share/fonts"
EXT_DIR="$HOME/.local/share/gnome-shell/extensions"
WALL_DIR="$HOME/Pictures/Wallpapers"

WITH_SUDO=false
GDM_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --with-sudo) WITH_SUDO=true ;;
    --gdm-only) GDM_ONLY=true; WITH_SUDO=true ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

shell_major() { gnome-shell --version 2>/dev/null | awk '{print $3}' | cut -d. -f1; }

# ── 1. Build dependencies (sudo) ───────────────────────────────
install_deps() {
  local missing=()
  for t in sassc glib-compile-resources xmllint convert 7z cpio fc-cache; do
    command -v "$t" >/dev/null 2>&1 || missing+=("$t")
  done
  ((${#missing[@]})) || { info "Build dependencies already present."; return; }

  if [[ "$WITH_SUDO" != true ]]; then
    warn "Missing tools: ${missing[*]}"
    warn "Re-run with --with-sudo to install sassc / imagemagick / libxml2-utils."
    die "Cannot continue without the theme build dependencies."
  fi
  info "Installing build dependencies (sudo)..."
  sudo apt-get update -qq
  sudo apt-get install -y sassc libglib2.0-dev-bin libxml2-utils imagemagick p7zip-full cpio
}

# ── 2. Themes, icons, cursors, wallpaper ───────────────────────
clone() {
  local repo="$1" dest="$2"
  if [[ -d "$dest/.git" ]]; then
    git -C "$dest" pull --ff-only --quiet || true
  else
    info "Cloning ${repo##*/}..."
    git clone --depth 1 --quiet "https://github.com/vinceliuice/$repo.git" "$dest"
  fi
}

install_look() {
  mkdir -p "$CACHE" "$THEMES" "$ICONS" "$FONTS" "$WALL_DIR"
  cd "$CACHE"

  clone WhiteSur-gtk-theme gtk
  clone WhiteSur-icon-theme icon
  clone WhiteSur-cursors cursors
  clone WhiteSur-wallpapers wallpapers

  # TERM must be set: the installer runs `setterm` and aborts without it.
  if [[ ! -d "$THEMES/$GTK_THEME" ]]; then
    info "Building the WhiteSur GTK theme (dark)..."
    TERM="${TERM:-xterm-256color}" bash gtk/install.sh -d "$THEMES" -c dark -t "$ACCENT" --round -l
  else
    info "GTK theme already installed."
  fi

  if [[ ! -d "$ICONS/$ICON_THEME" ]]; then
    info "Installing the WhiteSur icon theme..."
    TERM="${TERM:-xterm-256color}" bash icon/install.sh -d "$ICONS" -t default -a
  else
    info "Icon theme already installed."
  fi

  if [[ ! -d "$ICONS/WhiteSur-cursors" ]]; then
    info "Installing the WhiteSur cursors..."
    TERM="${TERM:-xterm-256color}" bash cursors/install.sh -d "$ICONS"
  else
    info "Cursor theme already installed."
  fi

  local wp
  wp="$(find wallpapers/4k -iname "$WALLPAPER" | head -1)"
  if [[ -n "$wp" ]]; then
    cp -f "$wp" "$WALL_DIR/$WALLPAPER"
    gsettings set org.gnome.desktop.background picture-options 'zoom'
    gsettings set org.gnome.desktop.background picture-uri "file://$WALL_DIR/$WALLPAPER"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALL_DIR/$WALLPAPER"
  fi
}

# ── 3. SF Pro (Apple) ──────────────────────────────────────────
install_fonts() {
  local dest="$FONTS/SF-Pro"
  if compgen -G "$dest/*.otf" >/dev/null; then
    info "SF Pro already installed."
    return
  fi
  info "Downloading SF Pro from Apple..."
  mkdir -p "$CACHE" && cd "$CACHE"
  curl -sSL -o SF-Pro.dmg "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg"

  rm -rf sf && mkdir -p sf && cd sf
  7z x -y -odmg ../SF-Pro.dmg >/dev/null
  7z x -y -opkg "$(find dmg -name '*.pkg' | head -1)" >/dev/null
  7z x -y -opl "$(find pkg -name Payload | head -1)" >/dev/null
  mkdir -p fs && (cd fs && cpio -idm <../pl/Payload~ 2>/dev/null)

  mkdir -p "$dest"
  find fs -iname '*.otf' -exec cp -f {} "$dest/" \;
  fc-cache -f "$FONTS" >/dev/null 2>&1
}

# ── 4. GNOME extensions ────────────────────────────────────────
EXTENSIONS=(
  "user-theme@gnome-shell-extensions.gcampax.github.com"
  "blur-my-shell@aunetx"
  "dash-to-dock@micxgx.gmail.com"
  "just-perfection-desktop@just-perfection"
)
# blur-my-shell stays enabled for the panel/dash/overview, but its `popup`
# component is turned off: it draws square corners over rounded popups on
# GNOME 50 (aunetx/blur-my-shell#900).
ENABLED_EXTENSIONS=(
  "user-theme@gnome-shell-extensions.gcampax.github.com"
  "blur-my-shell@aunetx"
  "dash-to-dock@micxgx.gmail.com"
  "just-perfection-desktop@just-perfection"
)

install_extensions() {
  local ver; ver="$(shell_major)"
  mkdir -p "$EXT_DIR" "$CACHE" && cd "$CACHE"

  for uuid in "${EXTENSIONS[@]}"; do
    [[ -f "$EXT_DIR/$uuid/metadata.json" ]] && { info "$uuid already installed."; continue; }

    local url
    url=$(curl -sS "https://extensions.gnome.org/extension-info/?uuid=${uuid}&shell_version=${ver}" \
      | python3 -c 'import json,sys; print(json.load(sys.stdin).get("download_url",""))' 2>/dev/null || true)
    if [[ -z "$url" ]]; then
      warn "$uuid has no build for GNOME $ver; skipping."
      continue
    fi

    info "Installing $uuid..."
    curl -sSL -o "$uuid.zip" "https://extensions.gnome.org${url}"
    rm -rf "$EXT_DIR/$uuid"; mkdir -p "$EXT_DIR/$uuid"
    unzip -q -o "$uuid.zip" -d "$EXT_DIR/$uuid"
    glib-compile-schemas "$EXT_DIR/$uuid/schemas" 2>/dev/null || true
  done
}

# ── 5. Apply settings ──────────────────────────────────────────
apply() {
  local IFACE=org.gnome.desktop.interface
  local WMP=org.gnome.desktop.wm.preferences

  info "Applying the macOS look..."
  gsettings set "$IFACE" gtk-theme "$GTK_THEME"
  gsettings set "$IFACE" icon-theme "$ICON_THEME"
  gsettings set "$IFACE" cursor-theme "$CURSOR_THEME"
  gsettings set "$IFACE" color-scheme 'prefer-dark'
  gsettings set "$IFACE" accent-color "$ACCENT"
  gsettings set "$IFACE" font-name 'SF Pro Display 11'
  gsettings set "$IFACE" document-font-name 'SF Pro Display 11'
  gsettings set "$IFACE" monospace-font-name 'SF Mono 11'
  gsettings set "$WMP" titlebar-font 'SF Pro Display Bold 11'
  # Window buttons stay on the right by preference.
  gsettings set "$WMP" button-layout ':minimize,maximize,close'
  gsettings set org.gnome.desktop.interface enable-animations true

  # Ubuntu's own dock stays enabled alongside Dash to Dock.
  gsettings set org.gnome.shell enabled-extensions \
    "['ding@rastersoft.com', 'tiling-assistant@ubuntu.com', 'snapd-search-provider@canonical.com', 'web-search-provider@ubuntu.com', '${ENABLED_EXTENSIONS[0]}', '${ENABLED_EXTENSIONS[1]}', '${ENABLED_EXTENSIONS[2]}', '${ENABLED_EXTENSIONS[3]}', 'ubuntu-dock@ubuntu.com']"

  # Extension schemas are not on the default search path.
  local G="$EXT_DIR/user-theme@gnome-shell-extensions.gcampax.github.com/schemas"
  GSETTINGS_SCHEMA_DIR="$G" gsettings set org.gnome.shell.extensions.user-theme name "$SHELL_THEME" || true

  G="$EXT_DIR/dash-to-dock@micxgx.gmail.com/schemas"
  for kv in "dock-position BOTTOM" "extend-height false" "autohide true" "dash-max-icon-size 48" "show-apps-at-top true"; do
    GSETTINGS_SCHEMA_DIR="$G" gsettings set org.gnome.shell.extensions.dash-to-dock ${kv} || true
  done

  G="$EXT_DIR/just-perfection-desktop@just-perfection/schemas"
  GSETTINGS_SCHEMA_DIR="$G" gsettings set org.gnome.shell.extensions.just-perfection activities-button true || true
  GSETTINGS_SCHEMA_DIR="$G" gsettings set org.gnome.shell.extensions.just-perfection clock-menu-position 1 || true

  # Blur only the panel and dock — enough for the look, lighter on the GPU —
  # and never the popups (see ENABLED_EXTENSIONS).
  G="$EXT_DIR/blur-my-shell@aunetx/schemas"
  for c in panel dash-to-dock; do
    GSETTINGS_SCHEMA_DIR="$G" gsettings set org.gnome.shell.extensions.blur-my-shell.$c blur true || true
  done
  for c in popup overview appfolder; do
    GSETTINGS_SCHEMA_DIR="$G" gsettings set org.gnome.shell.extensions.blur-my-shell.$c blur false || true
  done

  info "Done. Log out and back in for the shell theme and extensions."
}

# ── 6. GDM login screen (sudo) ─────────────────────────────────
install_gdm() {
  info "Installing the GDM (login screen) theme..."
  cd "$CACHE/gtk"
  TERM="${TERM:-xterm-256color}" sudo ./tweaks.sh -g
  info "To revert: TERM=xterm-256color sudo ./tweaks.sh -g -r"
}

# ── Run ────────────────────────────────────────────────────────
install_deps
if [[ "$GDM_ONLY" == true ]]; then
  install_gdm
  exit 0
fi

install_look
install_fonts
install_extensions
apply
[[ "$WITH_SUDO" == true ]] && install_gdm
