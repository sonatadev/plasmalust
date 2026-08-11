#!/bin/bash
# Installs the plasmalust SDDM theme system-wide and makes it the active
# login theme. Requires root - run with sudo.
#
# BEFORE running this: test the theme without touching your live login
# screen at all, using SDDM's built-in preview mode:
#
#   sddm-greeter-qt6 --test-mode --theme "$(dirname "$(readlink -f "$0")")"
#
# (older SDDM builds may name the binary just `sddm-greeter`). This opens
# the greeter in a normal window - your session keeps running, nothing
# system-wide is touched. Only run this install script once you're happy
# with what you saw there.
#
# Recovery, if something looks wrong after installing: switch to a TTY with
# Ctrl+Alt+F3 (or F2/F4), log in there, and run:
#   sudo rm /etc/sddm.conf.d/plasmalust.conf
#   sudo systemctl restart sddm
# to instantly fall back to the default theme.

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this with sudo." >&2
    exit 1
fi

REAL_USER="${SUDO_USER:-$(logname)}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STAGED_CONF="$REAL_HOME/.cache/wallust/sddm-theme.conf"
if [ ! -f "$STAGED_CONF" ]; then
    echo "Error: $STAGED_CONF not found. Run set-theme as $REAL_USER first." >&2
    exit 1
fi

THEME_DIR=/usr/share/sddm/themes/plasmalust
mkdir -p "$THEME_DIR"

cp "$SCRIPT_DIR/Main.qml" "$THEME_DIR/Main.qml"
cp "$SCRIPT_DIR/metadata.desktop" "$THEME_DIR/metadata.desktop"
cp "$STAGED_CONF" "$THEME_DIR/theme.conf"

# Reuse the same wallpaper-detection logic as set-theme, but reading the
# real user's config, not root's.
WALLPAPER=$(sudo -u "$REAL_USER" grep '^Image=' "$REAL_HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" | tail -n 1 | cut -d'=' -f2-)
WALLPAPER="${WALLPAPER#file://}"
if [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
    cp "$WALLPAPER" "$THEME_DIR/background.png"
else
    echo "Warning: could not detect wallpaper, theme will have no background image." >&2
fi

chmod -R a+rX "$THEME_DIR"

mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=plasmalust\n' > /etc/sddm.conf.d/plasmalust.conf

echo "Installed. The new theme takes effect on the next login screen (logout, or reboot to see it)."
echo "To revert: sudo rm /etc/sddm.conf.d/plasmalust.conf && sudo systemctl restart sddm"
