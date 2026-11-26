#!/usr/bin/env bash
# Screenshot helper for the Hyprland rice.
# Usage: screenshot.sh region|full|window
set -euo pipefail

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

case "${1:-region}" in
    region)
        geometry="$(slurp)" || exit 0
        grim -g "$geometry" "$file"
        ;;
    full)
        grim "$file"
        ;;
    window)
        geometry="$(hyprctl activewindow -j | jq -r 'if .at and .size then "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])" else empty end')"
        [ -n "$geometry" ] || exit 0
        grim -g "$geometry" "$file"
        ;;
    *)
        echo "usage: $0 region|full|window" >&2
        exit 2
        ;;
esac

wl-copy < "$file"
notify-send -a "Screenshot" -i camera-photo "Screenshot saved" "$file"
