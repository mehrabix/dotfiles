#!/usr/bin/env bash
# Prints a notification glyph + count for the Waybar custom module.
count="$(swaync-client -c 2>/dev/null || echo 0)"
case "$count" in
    ''|*[!0-9]*) count=0 ;;
esac
if [ "$count" -gt 0 ]; then
    printf '󰂚 %s\n' "$count"
fi
