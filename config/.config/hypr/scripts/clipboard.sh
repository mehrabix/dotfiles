#!/usr/bin/env bash
# Clipboard history picker: cliphist + wofi.
set -euo pipefail

entry="$(cliphist list | wofi --dmenu --prompt "  Clipboard" --width 720 --height 460 --cache-file /dev/null)" || exit 0
[ -n "$entry" ] || exit 0

printf '%s' "$entry" | cliphist decode | wl-copy
