#!/bin/bash
# Applies the wallust-generated color values (and current wallpaper) as
# their own independent GRUB theme, copied from Garuda's catppuccin-mocha
# theme but living in a separate directory. Requires root - run with sudo.
#
# Earlier versions of this script edited catppuccin-mocha's own theme.txt/
# background.png in place - which meant every `pacman -Syu` that touched
# that package silently reset them back to stock. Since GRUB_THEME's path
# is what's baked into grub.cfg, not its contents, moving to an independent
# plasmalust/ directory that no package owns means system updates can never
# touch it again - no more re-running this after every update.

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

SOURCE_DIR=/usr/share/grub/themes/catppuccin-mocha
THEME_DIR=/usr/share/grub/themes/plasmalust
THEME_TXT="$THEME_DIR/theme.txt"
BACKGROUND="$THEME_DIR/background.png"

mkdir -p "$THEME_DIR"

# One-time copy of the static assets our theme.txt references by relative
# filename (font, logo, selection-highlight pixmaps, icons) - these never
# change, so only copy them if they're not already here.
if [ ! -f "$THEME_DIR/logo.png" ]; then
    cp "$SOURCE_DIR/logo.png" "$SOURCE_DIR/select_c.png" "$SOURCE_DIR/select_e.png" \
       "$SOURCE_DIR/select_w.png" "$SOURCE_DIR/HackNerdMonoBold16.pf2" "$THEME_DIR/"
    cp -r "$SOURCE_DIR/icons" "$THEME_DIR/"
    echo "Copied static theme assets from $SOURCE_DIR"
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

# Point GRUB_THEME at our independent directory (only if it isn't already),
# and regenerate grub.cfg since this is a path change, not just a content
# change - unlike re-running this script normally, which never needs
# grub-mkconfig since the path stays the same.
if ! grep -q "^GRUB_THEME=\"$THEME_TXT\"" /etc/default/grub; then
    sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"$THEME_TXT\"|" /etc/default/grub
    echo "Updated GRUB_THEME in /etc/default/grub, regenerating grub.cfg..."
    grub-mkconfig -o /boot/grub/grub.cfg
fi

echo "GRUB theme updated. Changes show up on next boot."
