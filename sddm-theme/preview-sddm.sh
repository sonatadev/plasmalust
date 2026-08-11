#!/bin/bash
# Stages the current theme.conf + wallpaper into this directory (untracked -
# see .gitignore) and previews the greeter with SDDM's test-mode, which runs
# in an ordinary window and touches nothing system-wide. No sudo needed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STAGED_CONF="$HOME/.cache/wallust/sddm-theme.conf"
if [ ! -f "$STAGED_CONF" ]; then
    echo "Error: $STAGED_CONF not found. Run set-theme first." >&2
    exit 1
fi
cp "$STAGED_CONF" "$SCRIPT_DIR/theme.conf"

WALLPAPER=$(grep '^Image=' "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" | tail -n 1 | cut -d'=' -f2-)
WALLPAPER="${WALLPAPER#file://}"
if [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
    cp "$WALLPAPER" "$SCRIPT_DIR/background.png"
else
    echo "Warning: could not detect wallpaper, previewing without a background image." >&2
fi

GREETER=sddm-greeter-qt6
command -v "$GREETER" >/dev/null || GREETER=sddm-greeter
exec "$GREETER" --test-mode --theme "$SCRIPT_DIR"
