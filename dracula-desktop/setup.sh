#!/usr/bin/env bash
#
# dracula-desktop/setup.sh — glass/translucent GNOME look (Dracula by default).
#
# Works on Arch (pacman), Debian/Ubuntu (apt) and Fedora (dnf). Everything
# user-level lands in $HOME (themes, icons, cursors, fonts, extensions) and is
# applied with gsettings. Two things need root: the WhiteSur theme build
# dependencies (sassc, imagemagick, ...) and the GDM login screen theme. Both
# are only used by --whitesur / --with-sudo.
#
#   ./dracula-desktop/setup.sh                 Dracula + glass
#   ./dracula-desktop/setup.sh --solid         same, but no blur/transparency
#   ./dracula-desktop/setup.sh --whitesur      the old WhiteSur macOS look
#   ./dracula-desktop/setup.sh --with-sudo     + build deps + GDM theme
#   ./dracula-desktop/setup.sh --gdm-only      only the GDM login screen theme
#
set -euo pipefail

# ── Config ─────────────────────────────────────────────────────
# dracula: Dracula GTK (purple), Tela-circle icons, Catppuccin cursor, native
#          window buttons and Blur my Shell glass.
# whitesur: WhiteSur GTK + shell theme, WhiteSur icons/cursors, Sonoma wallpaper.
STYLE="dracula"
SOLID=false
WITH_SUDO=false
GDM_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --dracula) STYLE="dracula" ;;
    --whitesur) STYLE="whitesur" ;;
    --solid) SOLID=true ;;
    --with-sudo) WITH_SUDO=true ;;
    --gdm-only) GDM_ONLY=true; WITH_SUDO=true ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

WALLPAPER="Sonoma-dark.jpg"
DOCK_MONITOR="${DOCK_MONITOR:-HDMI-1}"      # connector the dock is pinned to

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/dracula-desktop"
THEMES="$HOME/.themes"
ICONS="$HOME/.local/share/icons"
FONTS="$HOME/.local/share/fonts"
EXT_DIR="$HOME/.local/share/gnome-shell/extensions"
SYS_EXT_DIR="/usr/share/gnome-shell/extensions"
WALL_DIR="$HOME/Pictures/Wallpapers"

case "$STYLE" in
  dracula)
    ACCENT="${ACCENT:-purple}"
    GTK_THEME="Dracula"
    ICON_THEME="Tela-circle-dracula-dark"
    CURSOR_THEME="${CURSOR_THEME:-catppuccin-mocha-dark-cursors}"
    SHELL_THEME=""                       # GNOME's own shell theme, no macOS chrome
    ;;
  whitesur)
    ACCENT="${ACCENT:-blue}"
    if [[ "$SOLID" == true ]]; then
      GTK_THEME="WhiteSur-Dark-solid-${ACCENT}"
    else
      GTK_THEME="WhiteSur-Dark-${ACCENT}"
    fi
    ICON_THEME="WhiteSur-dark"
    CURSOR_THEME="${CURSOR_THEME:-WhiteSur-cursors}"
    SHELL_THEME="WhiteSur-Dark-${ACCENT}"
    ;;
esac

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

shell_major() { gnome-shell --version 2>/dev/null | awk '{print $3}' | cut -d. -f1; }

run_root() {
  if [[ $EUID -eq 0 ]]; then "$@"
  elif command -v sudo >/dev/null 2>&1; then sudo "$@"
  else die "Root is required for: $*"
  fi
}

# Ubuntu Dock is Ubuntu's Dash to Dock fork and only exists on Ubuntu. Everywhere
# else we use upstream Dash to Dock. Both read the same dash-to-dock schema.
if [[ -d "$SYS_EXT_DIR/ubuntu-dock@ubuntu.com" ]]; then
  DOCK_EXT="ubuntu-dock@ubuntu.com"
else
  DOCK_EXT="dash-to-dock@micxgx.gmail.com"
fi

# ── 1. Build dependencies (sudo) ───────────────────────────────
install_deps() {
  local tools=(curl tar gjs glib-compile-schemas fc-cache unzip python3)
  # The WhiteSur theme is compiled from SCSS with ImageMagick, 7z and cpio.
  [[ "$STYLE" == "whitesur" ]] && tools+=(sassc glib-compile-resources xmllint convert 7z cpio)

  local missing=() t
  for t in "${tools[@]}"; do
    command -v "$t" >/dev/null 2>&1 || missing+=("$t")
  done
  ((${#missing[@]})) || { info "Dependencies already present."; return; }

  if [[ "$WITH_SUDO" != true ]]; then
    warn "Missing tools: ${missing[*]}"
    warn "Re-run with --with-sudo to install the theme build dependencies."
    die "Cannot continue without the theme build dependencies."
  fi
  info "Installing build dependencies (sudo)..."
  if command -v pacman >/dev/null 2>&1; then
    run_root pacman -S --needed --noconfirm \
      sassc glib2 libxml2 imagemagick 7zip cpio unzip python
  elif command -v apt-get >/dev/null 2>&1; then
    run_root apt-get update -qq
    run_root apt-get install -y \
      sassc libglib2.0-dev-bin libxml2-utils imagemagick p7zip-full cpio unzip python3
  elif command -v dnf >/dev/null 2>&1; then
    run_root dnf install -y \
      sassc glib2-devel libxml2 imagemagick p7zip cpio unzip python3
  else
    die "Install manually: ${missing[*]}"
  fi
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

  if [[ "$STYLE" == "whitesur" ]]; then
    install_whitesur
  else
    install_dracula
  fi

  link_gtk4
  set_cursor_default
}

install_whitesur() {
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
    # The upstream install.sh copies a relative `dist`, so it must run from its
    # own directory. It ignores -d and installs to $HOME/.local/share/icons.
    (cd cursors && TERM="${TERM:-xterm-256color}" bash install.sh)
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

# Dracula GTK is a colour theme (purple-tinted dark greys), Tela-circle adds a
# matching icon set. Both are plain tarballs from GitHub, no compiler needed.
install_dracula() {
  if [[ ! -d "$THEMES/Dracula" ]]; then
    info "Downloading the Dracula GTK theme..."
    curl -sSL -o dracula-gtk.tar.gz \
      "https://codeload.github.com/dracula/gtk/tar.gz/refs/heads/master"
    rm -rf dracula-gtk && mkdir -p dracula-gtk
    tar -xzf dracula-gtk.tar.gz -C dracula-gtk --strip-components=1
    cp -a dracula-gtk "$THEMES/Dracula"
  else
    info "Dracula GTK theme already installed."
  fi

  if [[ ! -d "$ICONS/$ICON_THEME" ]]; then
    info "Downloading the Tela-circle (Dracula) icon theme..."
    curl -sSL -o tela-circle.tar.gz \
      "https://codeload.github.com/vinceliuice/Tela-circle-icon-theme/tar.gz/refs/heads/master"
    rm -rf tela-circle && mkdir -p tela-circle
    tar -xzf tela-circle.tar.gz -C tela-circle --strip-components=1
    (cd tela-circle && bash install.sh -d "$ICONS" dracula)
  else
    info "Tela-circle icon theme already installed."
  fi
}

# GTK4/libadwaita apps ignore the GTK theme setting and read
# ~/.config/gtk-4.0/gtk.css instead. Link the active theme's CSS there so
# Nautilus, Settings, etc. get the same colours and translucency.
link_gtk4() {
  local g4="$HOME/.config/gtk-4.0"
  mkdir -p "$g4"
  rm -f "$g4/gtk.css" "$g4/gtk-dark.css" "$g4/assets" "$g4/windows-assets"

  if [[ "$STYLE" == "whitesur" ]]; then
    ln -sfn "$THEMES/$GTK_THEME/gtk-4.0/gtk-dark.css" "$g4/gtk.css"
    ln -sfn "$THEMES/$GTK_THEME/gtk-4.0/gtk-dark.css" "$g4/gtk-dark.css"
    for d in assets windows-assets; do
      ln -sfn "$THEMES/$GTK_THEME/gtk-4.0/$d" "$g4/$d"
    done
  else
    ln -sfn "$THEMES/Dracula/gtk-4.0/gtk-dark.css" "$g4/gtk.css"
    ln -sfn "$THEMES/Dracula/gtk-4.0/gtk-dark.css" "$g4/gtk-dark.css"
    # Dracula's gtk-4.0 CSS refers to ../assets, i.e. ~/.config/assets.
    ln -sfn "$THEMES/Dracula/assets" "$HOME/.config/assets"
  fi
}

# X11/XWayland apps read ~/.icons/default instead of the gsettings key.
set_cursor_default() {
  local cursor="${CURSOR_THEME:-}"
  have_cursor || cursor="Adwaita"
  [[ -n "$cursor" ]] || return 0
  mkdir -p "$HOME/.icons/default"
  printf '[Icon Theme]\nName=Default\nInherits=%s\n' "$cursor" \
    > "$HOME/.icons/default/index.theme"
}

# Fall back to Adwaita when the wanted cursor/icon set is not installed.
have_cursor() { [[ -d "$ICONS/$CURSOR_THEME" || -d "/usr/share/icons/$CURSOR_THEME" ]]; }
have_icons()  { [[ -d "$ICONS/$ICON_THEME"  || -d "/usr/share/icons/$ICON_THEME" ]]; }

# ── 3. SF Pro / SF Mono (Apple) ────────────────────────────────
extract_dmg_fonts() {
  local dmg="$1" dest="$2" work="$3"
  rm -rf "$work" && mkdir -p "$work" && cd "$work"
  7z x -y -odmg "../$dmg" >/dev/null
  7z x -y -opkg "$(find dmg -name '*.pkg' | head -1)" >/dev/null
  7z x -y -opl "$(find pkg -name Payload | head -1)" >/dev/null
  mkdir -p fs && (cd fs && cpio -idm <../pl/Payload~ 2>/dev/null)

  mkdir -p "$dest"
  find fs \( -iname '*.otf' -o -iname '*.ttf' \) -exec cp -f {} "$dest/" \;
}

install_fonts() {
  local pro="$FONTS/SF-Pro" mono="$FONTS/SF-Mono"
  mkdir -p "$CACHE" && cd "$CACHE"

  if compgen -G "$pro/*.otf" >/dev/null; then
    info "SF Pro already installed."
  else
    info "Downloading SF Pro from Apple..."
    curl -sSL -o SF-Pro.dmg "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg"
    extract_dmg_fonts SF-Pro.dmg "$pro" sf-pro
  fi

  # SF Mono ships in its own DMG; the terminal profile asks for "SF Mono 12".
  if compgen -G "$mono/*.[ot]tf" >/dev/null; then
    info "SF Mono already installed."
  else
    info "Downloading SF Mono from Apple..."
    curl -sSL -o SF-Mono.dmg "https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg"
    extract_dmg_fonts SF-Mono.dmg "$mono" sf-mono
  fi

  fc-cache -f "$FONTS" >/dev/null 2>&1
}

# ── 4. GNOME extensions ────────────────────────────────────────
# Extensions that the distro already packages are left to the package manager
# (Arch: user-theme, dash-to-dock, appindicator, desktop-icons-ng). Only the
# missing ones are downloaded from extensions.gnome.org.
#
# Blur my Shell provides the transparency effects; Hibernate Power Menu adds
# the Hibernate item GNOME 51 lacks.
EXTENSIONS=(
  "user-theme@gnome-shell-extensions.gcampax.github.com"
  "just-perfection-desktop@just-perfection"
  "blur-my-shell@aunetx"
  "hibernate-power-menu@arnakazim"
)
# Familiar Ubuntu bits, enabled only when present on this machine.
COMPANION_EXTENSIONS=(
  "ding@rastersoft.com"
  "tiling-assistant@ubuntu.com"
  "ubuntu-appindicators@ubuntu.com"
  "appindicatorsupport@rgcjonas.gmail.com"
)
# Leftovers from older revisions of this script; removed if present.
LEGACY_EXTENSIONS=(
  "trayIconsReloaded@selfmade.pl"
)

ext_installed() {
  local uuid="$1"
  [[ -f "$SYS_EXT_DIR/$uuid/metadata.json" || -f "$EXT_DIR/$uuid/metadata.json" ]]
}

install_extensions() {
  local ver; ver="$(shell_major)"
  mkdir -p "$EXT_DIR" "$CACHE" && cd "$CACHE"

  for uuid in "$DOCK_EXT" "${EXTENSIONS[@]}"; do
    if [[ -f "$EXT_DIR/$uuid/metadata.json" ]]; then
      info "$uuid already installed (user)."
      continue
    fi
    if [[ -f "$SYS_EXT_DIR/$uuid/metadata.json" ]]; then
      info "$uuid already installed (system)."
      continue
    fi

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

remove_legacy_extensions() {
  local uuid
  for uuid in "${LEGACY_EXTENSIONS[@]}"; do
    [[ -d "$EXT_DIR/$uuid" ]] || continue
    info "Removing legacy extension $uuid..."
    gnome-extensions disable "$uuid" 2>/dev/null || true
    rm -rf "$EXT_DIR/$uuid"
  done
}

# Set a key on an extension schema that may live in the user extension dir.
gs_ext() {
  local uuid="$1" schema="$2" key="$3" value="$4"
  local dir="$EXT_DIR/$uuid/schemas"
  # No `grep -q`: it exits early and, under `pipefail`, gsettings' SIGPIPE makes
  # the pipeline look like a failure.
  if gsettings list-schemas | grep -x "$schema" >/dev/null; then
    gsettings set "$schema" "$key" "$value" 2>/dev/null || true
  elif [[ -d "$dir" ]]; then
    GSETTINGS_SCHEMA_DIR="$dir" gsettings set "$schema" "$key" "$value" 2>/dev/null || true
  else
    warn "Schema $schema not found; skipping $key."
  fi
}

# ── 5. macOS-style translucency ────────────────────────────────
# Blur my Shell blurs the shell (panel/dash/overview/popups), like the macOS
# menu bar, and gives application windows a barely-there frost.
# Windows are effectively opaque (250/255 ≈ 98 %): the desktop must not show
# through the UI, only the chrome carries the translucent tint.
apply_transparency() {
  [[ "$SOLID" == true ]] && return 0

  local BMS="blur-my-shell@aunetx"
  if ! ext_installed "$BMS"; then
    warn "Blur my Shell is not installed; skipping the transparency settings."
    return 0
  fi

  info "Enabling macOS-style translucency (Blur my Shell)..."
  # Shell chrome: blurred backdrop under a dark tint (0 = no tint, 2 = dark),
  # so the panel, dock and menus read as solid surfaces like macOS.
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.panel blur true
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.panel static-blur true
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.panel style-panel 2
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.panel unblur-in-overview false
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.dash-to-dock blur true
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.dash-to-dock static-blur true
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.dash-to-dock style-dash-to-dock 2
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.popup blur true
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.popup style-popup 2
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.overview blur true
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.appfolder blur true
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.lockscreen blur true
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.window-list blur true

  # Every application window: effectively opaque over a very soft blurred
  # backdrop, the way macOS keeps window content opaque and only adds vibrancy
  # to the chrome. opacity is 25-255 (higher = more legible); at 250 the desktop
  # is no longer visible through a window. Corner rounding is left to the GTK
  # theme: Blur my Shell clipping at a different radius drew a second arc on top
  # of the theme's rounded corners (rounded-corners 3 = do not round).
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.applications blur true
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.applications enable-all true
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.applications static-blur true
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.applications opacity 250
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.applications sigma 12
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.applications dynamic-opacity false
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.applications blur-on-overview false
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.applications unblur-when-fullscreen true
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.applications rounded-corners 3
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.applications corner-radius 12
  gs_ext "$BMS" org.gnome.shell.extensions.blur-my-shell.applications corner-when-maximized false

  # Ptyxis has its own background opacity; the other apps get translucency from
  # the theme + Blur my Shell.
  if command -v ptyxis >/dev/null 2>&1 && gsettings list-schemas 2>/dev/null | grep -x 'org.gnome.Ptyxis' >/dev/null; then
    local uuid
    uuid="$(gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'")"
    [[ "$uuid" == "@as []" || "$uuid" == "[]" ]] && uuid=""
    if [[ -z "$uuid" ]]; then
      uuid="$(gsettings get org.gnome.Ptyxis profile-uuids 2>/dev/null \
        | grep -oE '[0-9a-f]{16,}' | head -1)"
    fi
    if [[ -n "$uuid" ]]; then
      gsettings set "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${uuid}/" opacity 0.95 2>/dev/null || true
    fi
  fi

  # Load it in the running session; without this it would only appear on login.
  gnome-extensions enable "$BMS" 2>/dev/null || true
}

# ── 7. Apply settings ──────────────────────────────────────────
apply() {
  local IFACE=org.gnome.desktop.interface
  local WMP=org.gnome.desktop.wm.preferences
  local icons="$ICON_THEME" cursor="$CURSOR_THEME"

  have_icons  || { warn "$ICON_THEME is missing; keeping Adwaita icons."; icons="Adwaita"; }
  have_cursor || { warn "$CURSOR_THEME is missing; keeping Adwaita cursors."; cursor="Adwaita"; }

  info "Applying the $STYLE look..."
  gsettings set "$IFACE" gtk-theme "$GTK_THEME"
  gsettings set "$IFACE" icon-theme "$icons"
  gsettings set "$IFACE" cursor-theme "$cursor"
  gsettings set "$IFACE" color-scheme 'prefer-dark'
  gsettings set "$IFACE" accent-color "$ACCENT"
  gsettings set "$IFACE" font-name 'SF Pro Display 11'
  gsettings set "$IFACE" document-font-name 'SF Pro Display 11'
  gsettings set "$IFACE" monospace-font-name 'SF Mono 11'
  gsettings set "$WMP" titlebar-font 'SF Pro Display Bold 11'
  gsettings set "$WMP" theme "$GTK_THEME"
  # Native GNOME window buttons on the right (not the macOS traffic lights of --whitesur).
  gsettings set "$WMP" button-layout ':minimize,maximize,close'
  # Panel/desktop touches: battery percentage, a clock with the weekday, a
  # top-left hot corner for the Overview, and workspaces on every display.
  gsettings set "$IFACE" enable-animations true
  gsettings set "$IFACE" show-battery-percentage true
  gsettings set "$IFACE" clock-show-weekday true
  gsettings set "$IFACE" enable-hot-corners true
  gsettings set org.gnome.mutter workspaces-only-on-primary false

  # Switch keyboard layouts with Alt+Shift on either side and in either order.
  # XKB's grp:alt_shift_toggle only pairs same-side keys and is order-sensitive
  # (pressing Shift before Alt would not switch), so we bind the shell's
  # switch-input-source instead. lv3:ralt_alt keeps Right Alt a plain Alt so it
  # can take part in the chord rather than acting as AltGr.
  gsettings set org.gnome.desktop.input-sources xkb-options "['lv3:ralt_alt']"
  gsettings set org.gnome.desktop.wm.keybindings switch-input-source \
    "['<Shift>Alt_L', '<Alt>Shift_L', '<Shift>Alt_R', '<Alt>Shift_R']"

  # Enable only the extensions that exist here. A literal list of Ubuntu UUIDs
  # would make GNOME Shell log errors for missing extensions on Arch.
  local list="" uuid
  for uuid in "$DOCK_EXT" "${COMPANION_EXTENSIONS[@]}" "${EXTENSIONS[@]}"; do
    ext_installed "$uuid" || continue
    list+="'$uuid', "
  done
  list="${list%, }"
  if [[ -n "$list" ]]; then
    gsettings set org.gnome.shell enabled-extensions "[$list]"
  fi

  if [[ "$STYLE" == "whitesur" ]]; then
    gs_ext "user-theme@gnome-shell-extensions.gcampax.github.com" \
      org.gnome.shell.extensions.user-theme name "$SHELL_THEME"
  else
    # No shell theme: GNOME's own chrome, blurred by Blur my Shell.
    gs_ext "user-theme@gnome-shell-extensions.gcampax.github.com" \
      org.gnome.shell.extensions.user-theme name ""
  fi

  # Dash to Dock / Ubuntu Dock: pin to a display by connector name (HDMI-1 is
  # the external monitor; the laptop panel is eDP-1). `preferred-monitor -2`
  # means "use the connector".
  for kv in "dock-position BOTTOM" "extend-height false" "autohide true" \
            "dash-max-icon-size 42" "show-apps-at-top false" \
            "click-action minimize" "scroll-action switch-workspace" \
            "middle-click-action launch" "preferred-monitor -2" \
            "preferred-monitor-by-connector $DOCK_MONITOR"; do
    # shellcheck disable=SC2086
    gs_ext "$DOCK_EXT" org.gnome.shell.extensions.dash-to-dock ${kv}
  done

  gs_ext "just-perfection-desktop@just-perfection" \
    org.gnome.shell.extensions.just-perfection activities-button true
  gs_ext "just-perfection-desktop@just-perfection" \
    org.gnome.shell.extensions.just-perfection clock-menu-position 1

  # GNOME only shows Log Out for multi-user/multi-session machines; keep it in
  # the power menu for this single-user laptop.
  gsettings set org.gnome.shell always-show-log-out true
  # Hibernate item in the power menu. The extension greys it out when the
  # system cannot hibernate (no swap/resume configured). Hybrid sleep is left
  # hidden; enable it in the extension's preferences if wanted.
  gs_ext "hibernate-power-menu@arnakazim" \
    org.gnome.shell.extensions.hibernate-power-menu show-hibernate true
  gs_ext "hibernate-power-menu@arnakazim" \
    org.gnome.shell.extensions.hibernate-power-menu show-hybrid-sleep false

  # Super+E opens the file manager, like Windows Explorer.
  local MEDIA=org.gnome.settings-daemon.plugins.media-keys
  local CK="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
  gsettings set "$MEDIA" custom-keybindings "['$CK']"
  gsettings set "$MEDIA.custom-keybinding:$CK" name 'Files'
  gsettings set "$MEDIA.custom-keybinding:$CK" command 'nautilus'
  gsettings set "$MEDIA.custom-keybinding:$CK" binding '<Super>e'

  # Rounded dock corners come from the shell theme (--whitesur); with GNOME's
  # own theme Blur my Shell supplies the translucent backdrop.

  info "Done. Log out and back in for the theme and extensions."
}

# ── 8. GDM login screen (sudo, --whitesur only) ────────────────
install_gdm() {
  if [[ "$STYLE" != "whitesur" ]]; then
    warn "The GDM theme is a WhiteSur tweak; run with --whitesur --gdm-only."
    return 0
  fi
  if [[ ! -d /usr/share/gdm ]]; then
    warn "GDM does not seem to be installed; skipping the login screen theme."
    return 0
  fi
  info "Installing the GDM (login screen) theme..."
  cd "$CACHE/gtk"
  TERM="${TERM:-xterm-256color}" run_root ./tweaks.sh -g
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
remove_legacy_extensions
apply
apply_transparency
if [[ "$WITH_SUDO" == true ]]; then
  install_gdm
fi
