#!/bin/bash
# Installs the plasmalust KSplash theme (the loading screen shown between
# login and the desktop appearing) system-wide and makes it active.
# Requires root - run with sudo.
#
# BEFORE running this: preview it without touching anything system-wide,
# using ksplashqml's own test mode:
#
#   ksplashqml "$(dirname "$(readlink -f "$0")")" --test --window
#
# (this runs against the repo copy directly - the colors/portrait won't be
# staged yet the very first time; run set-theme once first if the images/
# dir below doesn't exist.) Only run this install script once you're happy
# with what you saw there.
#
# Recovery, if something looks wrong after installing: it only affects the
# splash screen, not login or the desktop itself, so just log in normally
# and run:
#   sudo rm /etc/xdg/ksplashrc.d/plasmalust.conf   # if present
#   kwriteconfig6 --file ksplashrc --group KSplash --key Theme org.kde.breeze.desktop
# to fall back to the default.

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this with sudo." >&2
    exit 1
fi

REAL_USER="${SUDO_USER:-$(logname)}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STAGED_QML="$REAL_HOME/.cache/wallust/ksplash-Splash.qml"
if [ ! -f "$STAGED_QML" ]; then
    echo "Error: $STAGED_QML not found. Run set-theme as $REAL_USER first." >&2
    exit 1
fi

THEME_DIR=/usr/share/plasma/look-and-feel/plasmalust.splash
mkdir -p "$THEME_DIR/contents/splash/images"

cp "$SCRIPT_DIR/metadata.json" "$THEME_DIR/metadata.json"
cp "$STAGED_QML" "$THEME_DIR/contents/splash/Splash.qml"

PORTRAIT="$REAL_HOME/.cache/wallust/portrait-dither.png"
if [ -f "$PORTRAIT" ]; then
    cp "$PORTRAIT" "$THEME_DIR/contents/splash/images/portrait.png"
else
    echo "Warning: $PORTRAIT not found, splash will have no portrait image." >&2
fi

chmod -R a+rX "$THEME_DIR"

sudo -u "$REAL_USER" kwriteconfig6 --file ksplashrc --group KSplash --key Theme plasmalust.splash

echo "Installed. The new splash shows on the next login (logout, or reboot to see it)."
echo "To revert: kwriteconfig6 --file ksplashrc --group KSplash --key Theme org.kde.breeze.desktop"
