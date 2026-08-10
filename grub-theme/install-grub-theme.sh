#!/bin/bash
# Applies the wallust-generated color values to Garuda's catppuccin-mocha
# GRUB theme. Requires root - run with sudo.
#
# Only colors in theme.txt change; images, fonts, and layout are untouched.
# GRUB reads theme.txt directly at boot (the path is already set via
# GRUB_THEME in /etc/default/grub), so no `grub-mkconfig` is needed.
#
# A GRUB gfxmenu error normally just falls back to GRUB's plain text menu,
# not an unbootable system - but this script backs up the original
# theme.txt on first run regardless, so it's trivially reversible:
#   sudo cp /usr/share/grub/themes/catppuccin-mocha/theme.txt.orig \
#           /usr/share/grub/themes/catppuccin-mocha/theme.txt

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this with sudo." >&2
    exit 1
fi

REAL_USER="${SUDO_USER:-$(logname)}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

STAGED="$REAL_HOME/.cache/wallust/grub-theme.txt"
if [ ! -f "$STAGED" ]; then
    echo "Error: $STAGED not found. Run set-theme as $REAL_USER first." >&2
    exit 1
fi

THEME_TXT=/usr/share/grub/themes/catppuccin-mocha/theme.txt

if [ ! -f "$THEME_TXT.orig" ]; then
    cp "$THEME_TXT" "$THEME_TXT.orig"
    echo "Backed up original to $THEME_TXT.orig"
fi

cp "$STAGED" "$THEME_TXT"
echo "GRUB theme colors updated. Changes show up on next boot."
