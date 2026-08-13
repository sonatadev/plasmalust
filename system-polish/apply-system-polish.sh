#!/bin/bash
# One-time system chrome setup - not part of the recurring set-theme
# pipeline since these are structural/app settings, not palette-driven
# ones (the actual *colors* used below are regenerated dynamically by
# set-theme on every wallpaper change, via the [templates.kvantum] entry
# in wallust.toml - this script just wires the plumbing up once).
#
# - KWin: enables the "Rounded Corners" (kwin4_effect_shapecorners)
#   compositor effect globally, so every window gets rounded corners
#   matching the widgets' rounded frames.
# - Kvantum: creates a "Plasmalust" Qt widget theme (rounded-corner shapes
#   borrowed from KvArcDark, colors wallust-templated - see
#   templates/kvantum-plasmalust.kvconfig) and makes it the active Qt6
#   style, so Dolphin (and other Qt/KDE apps) pick up rounded, themed
#   widgets instead of flat stock Breeze.
#   Note: window.color and base.color (sidebar/toolbar and item view
#   backgrounds) are templated much lighter than the rest of the theme
#   on purpose - Dolphin's file labels AND its Places sidebar entries
#   both render with a fixed, non-themeable dark caption color (confirmed
#   by testing - no GeneralColors key changes it), so a fully dark
#   background makes that text unreadable. See kvantum-plasmalust.kvconfig.
# - KWin window rule: makes Spotify's window translucent (blurred behind,
#   via the already-enabled blur effect) so it matches the rest of the
#   translucent/blurred system chrome.
# - kitty: user-level .desktop override adding --single-instance. New OS
#   windows are opened in an already-running kitty process (shares its GPU
#   sprite cache) instead of a full cold start - measured ~270ms cold vs
#   ~25ms warm. The Meta+T global shortcut launches kitty.desktop directly
#   (see kglobalshortcutsrc), so this one file covers the shortcut, the app
#   launcher, and the taskbar icon. First open with no kitty running yet is
#   still a cold start - single-instance doesn't keep a window-less process
#   alive in the background.
# - yazi: installs a yazi.desktop (kitty --single-instance -e yazi) and sets
#   it as the default handler for inode/directory via xdg-mime, so it's the
#   system default file manager. Also adds a Meta+E global shortcut - note
#   this requires kglobalaccel (hosted inside kded6) to re-scan shortcuts,
#   which only happens on next login/kded6 restart; it's saved either way.
# - kitty pre-warm: autostarts a hidden `kitty --single-instance --start-as=
#   hidden` at login. Single-instance mode already makes every window after
#   the first fast, but with nothing running yet, the *first* window of a
#   session still pays kitty's cold GPU-context startup cost (~270ms
#   measured). A hidden warm instance from login means there's never a
#   genuine "first" window from the user's perspective - measured ~29ms
#   even opening on a completely empty desktop.
set -euo pipefail

KVANTUM_SRC_THEME="/usr/share/Kvantum/KvArcDark/KvArcDark.svg"
KVANTUM_DEST_DIR="$HOME/.config/Kvantum/Plasmalust"

# 1. Rounded corners everywhere
kwriteconfig6 --file kwinrc --group Plugins --key kwin4_effect_shapecornersEnabled --type bool true
kwriteconfig6 --file kwinrc --group Round-Corners --key Size --type int 20
kwriteconfig6 --file kwinrc --group Round-Corners --key InactiveCornerRadius --type int 20

# 2. Kvantum "Plasmalust" theme: shape (SVG) is a one-time copy from KvArcDark,
# colors are templated by wallust (regenerated on every set-theme run).
mkdir -p "$KVANTUM_DEST_DIR"
if [ -f "$KVANTUM_SRC_THEME" ]; then
    cp "$KVANTUM_SRC_THEME" "$KVANTUM_DEST_DIR/Plasmalust.svg"
else
    echo "Warning: $KVANTUM_SRC_THEME not found - install the 'kvantum-theme' package (KvArcDark) first." >&2
fi
kwriteconfig6 --file "$HOME/.config/Kvantum/kvantum.kvconfig" --group General --key theme "Plasmalust"
kwriteconfig6 --file kdeglobals --group General --key widgetStyle "kvantum"
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle "kvantum"

# 3. Spotify: translucent + blurred window (matches the rest of the
# translucent system chrome). Merges into any existing rule list instead
# of clobbering it.
kwriteconfig6 --file kwinrulesrc --group Spotify --key Description "Spotify - transparency"
kwriteconfig6 --file kwinrulesrc --group Spotify --key wmclass "spotify"
kwriteconfig6 --file kwinrulesrc --group Spotify --key wmclassmatch --type int 1
kwriteconfig6 --file kwinrulesrc --group Spotify --key wmclasscomplete --type bool false
kwriteconfig6 --file kwinrulesrc --group Spotify --key types --type int 1
kwriteconfig6 --file kwinrulesrc --group Spotify --key opacityactive --type int 90
kwriteconfig6 --file kwinrulesrc --group Spotify --key opacityactiverule --type int 2
kwriteconfig6 --file kwinrulesrc --group Spotify --key opacityinactive --type int 78
kwriteconfig6 --file kwinrulesrc --group Spotify --key opacityinactiverule --type int 2

EXISTING_RULES=$(kreadconfig6 --file kwinrulesrc --group General --key rules)
if [[ ",$EXISTING_RULES," != *",Spotify,"* ]]; then
    if [ -z "$EXISTING_RULES" ]; then
        kwriteconfig6 --file kwinrulesrc --group General --key rules "Spotify"
    else
        kwriteconfig6 --file kwinrulesrc --group General --key rules "$EXISTING_RULES,Spotify"
    fi
fi

qdbus6 org.kde.KWin /KWin reconfigure

# 4. kitty: single-instance new windows (see note above)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$HOME/.local/share/applications"
cp "$SCRIPT_DIR/../dotfiles/kitty.desktop" "$HOME/.local/share/applications/kitty.desktop"
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

# 5. yazi: default file manager (see note above)
cp "$SCRIPT_DIR/../dotfiles/yazi.desktop" "$HOME/.local/share/applications/yazi.desktop"
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
xdg-mime default yazi.desktop inode/directory
kwriteconfig6 --file kglobalshortcutsrc --group "services" --group "yazi.desktop" --key "_launch" "Meta+E,Meta+E,Yazi"

# 6. kitty pre-warm autostart (see note above)
mkdir -p "$HOME/.config/autostart"
cp "$SCRIPT_DIR/../dotfiles/kitty-prewarm-autostart.desktop" "$HOME/.config/autostart/kitty-prewarm.desktop"
pgrep -x kitty >/dev/null || (kitty --single-instance --start-as=hidden &>/dev/null & disown)

echo "System polish applied. Run set-theme once to render Kvantum's wallust colors,"
echo "then restart plasmashell/relaunch Dolphin and Spotify to pick everything up."
