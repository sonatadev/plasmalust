#!/bin/bash
# Applies the wallust-generated color values (and current wallpaper) to
# Garuda's catppuccin-mocha GRUB theme. Requires root - run with sudo.
#
# GRUB reads theme.txt directly at boot (the path is already set via
# GRUB_THEME in /etc/default/grub), so no `grub-mkconfig` is needed.
#
# A GRUB gfxmenu error normally just falls back to GRUB's plain text menu,
# not an unbootable system - but this script backs up the originals on
# first run regardless, so it's trivially reversible:
#   sudo cp /usr/share/grub/themes/catppuccin-mocha/theme.txt.orig \
#           /usr/share/grub/themes/catppuccin-mocha/theme.txt
#   sudo cp /usr/share/grub/themes/catppuccin-mocha/background.png.orig \
#           /usr/share/grub/themes/catppuccin-mocha/background.png

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

THEME_DIR=/usr/share/grub/themes/catppuccin-mocha
THEME_TXT="$THEME_DIR/theme.txt"
BACKGROUND="$THEME_DIR/background.png"

if [ ! -f "$THEME_TXT.orig" ]; then
    cp "$THEME_TXT" "$THEME_TXT.orig"
    echo "Backed up original to $THEME_TXT.orig"
fi
if [ ! -f "$BACKGROUND.orig" ]; then
    cp "$BACKGROUND" "$BACKGROUND.orig"
    echo "Backed up original to $BACKGROUND.orig"
fi

cp "$STAGED" "$THEME_TXT"

# Wallpaper - GRUB has no hardware-accelerated scaling and only a minimal
# image decoder, so resize down at generation time rather than making GRUB
# scale a full-resolution photo at boot. Darkened the same way as the
# plasmalogin greeter, for text legibility against a busy photo instead of
# a flat color.
WALLPAPER=$(sudo -u "$REAL_USER" grep '^Image=' "$REAL_HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" | tail -n 1 | cut -d'=' -f2-)
WALLPAPER="${WALLPAPER#file://}"
if [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ] && command -v magick >/dev/null; then
    magick "$WALLPAPER" -resize 1920x1080^ -gravity center -extent 1920x1080 -colorize 35% "$BACKGROUND"
else
    echo "Warning: could not update GRUB background image, keeping the existing one." >&2
fi

echo "GRUB theme updated. Changes show up on next boot."
