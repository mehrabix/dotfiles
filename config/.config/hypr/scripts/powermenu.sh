#!/usr/bin/env bash
# Power menu rendered with wofi.
set -euo pipefail

options=$'󰌾  Lock\n󰍃  Logout\n󰒲  Suspend\n󰜉  Reboot\n󰐥  Shutdown'
chosen="$(printf '%s\n' "$options" | wofi --dmenu --prompt "  Power" --width 340 --height 330 --cache-file /dev/null)" || exit 0

case "$chosen" in
    *Lock*)     loginctl lock-session ;;
    *Logout*)   hyprctl dispatch 'hl.dsp.exit()' ;;
    *Suspend*)  systemctl suspend ;;
    *Reboot*)   systemctl reboot ;;
    *Shutdown*) systemctl poweroff ;;
esac
