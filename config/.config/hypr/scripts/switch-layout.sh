#!/usr/bin/env bash
# Switch the active keyboard layout (US <-> Persian), like GNOME's SUPER+Space.
#
# Hyprland tracks the layout group per keyboard device, so switch every device
# to keep the focused keyboard and the main keyboard in sync.
set -euo pipefail

hyprctl switchxkblayout all next >/dev/null

# Small OSD feedback that matches the rest of the desktop.
if command -v swayosd-client >/dev/null 2>&1; then
    layout="$(hyprctl devices -j 2>/dev/null \
        | jq -r '.keyboards[] | select(.main == true) | .active_keymap' 2>/dev/null \
        | head -n1)"
    if [ -n "${layout:-}" ]; then
        swayosd-client --custom-message "$layout" --custom-icon input-keyboard-symbolic >/dev/null 2>&1 || true
    fi
fi
