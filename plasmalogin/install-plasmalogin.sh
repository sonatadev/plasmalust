#!/bin/bash
# Syncs the current wallpaper + wallust color scheme to plasmalogin, the
# actual active login greeter on this system (not SDDM - see README).
# Requires root - run with sudo.
#
# plasmalogin runs as its own restricted system user (uid/gid "plasmalogin",
# home /var/lib/plasmalogin) with its own isolated config, entirely separate
# from your own ~/.config - so the color scheme wallust already generates
# for your desktop session doesn't reach it automatically. This copies that
# same scheme into plasmalogin's own home and points its own kdeglobals at
# it, plus syncs the greeter wallpaper the same way.

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this with sudo." >&2
    exit 1
fi

REAL_USER="${SUDO_USER:-$(logname)}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
PL_HOME=$(getent passwd plasmalogin | cut -d: -f6)
if [ -z "$PL_HOME" ]; then
    echo "Error: no 'plasmalogin' system user found - is plasmalogin actually installed/active here?" >&2
    exit 1
fi

# Wallpaper - same detection set-theme itself uses, reading the real user's
# config, not root's.
WALLPAPER=$(sudo -u "$REAL_USER" grep '^Image=' "$REAL_HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" | tail -n 1 | cut -d'=' -f2-)
WALLPAPER="${WALLPAPER#file://}"
if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
    echo "Error: could not detect current wallpaper." >&2
    exit 1
fi

WALLPAPER_DIR="$PL_HOME/wallpapers"
mkdir -p "$WALLPAPER_DIR"
DEST_WALLPAPER="$WALLPAPER_DIR/wallust.${WALLPAPER##*.}"
cp "$WALLPAPER" "$DEST_WALLPAPER"

mkdir -p /etc
cat > /etc/plasmalogin.conf << EOF
[Greeter][Wallpaper][org.kde.image][General]
Image=file://$DEST_WALLPAPER
EOF

# Color scheme - copy the most recently generated Wallust-*.colors from the
# real user's color-schemes dir into plasmalogin's own, and point its own
# kdeglobals at it. plasmalogin isn't a running session, so there's no
# plasma-apply-colorscheme D-Bus call to make here - writing kdeglobals
# directly is the equivalent for a not-yet-started greeter.
LATEST_SCHEME=$(find "$REAL_HOME/.local/share/color-schemes" -maxdepth 1 -name 'Wallust-*.colors' -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
if [ -z "$LATEST_SCHEME" ]; then
    echo "Error: no Wallust-*.colors found in $REAL_HOME/.local/share/color-schemes - run set-theme first." >&2
    exit 1
fi
SCHEME_NAME=$(basename "$LATEST_SCHEME" .colors)

mkdir -p "$PL_HOME/.local/share/color-schemes" "$PL_HOME/.config"
cp "$LATEST_SCHEME" "$PL_HOME/.local/share/color-schemes/$SCHEME_NAME.colors"
find "$PL_HOME/.local/share/color-schemes" -maxdepth 1 -name 'Wallust-*.colors' ! -name "$SCHEME_NAME.colors" -delete

kwriteconfig6 --file "$PL_HOME/.config/kdeglobals" --group General --key ColorScheme "$SCHEME_NAME"

chown -R plasmalogin:plasmalogin "$PL_HOME"

echo "plasmalogin wallpaper + colors updated. Takes effect on next logout/reboot."
