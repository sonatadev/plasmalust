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

echo "System polish applied. Run set-theme once to render Kvantum's wallust colors,"
echo "then restart plasmashell/relaunch Dolphin and Spotify to pick everything up."
