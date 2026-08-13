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
#   system default file manager. Its Meta+E shortcut is set up by the
#   plasmalust-shortcuts KWin script below, not a kglobalshortcutsrc
#   "_launch" binding - see that step's note for why.
# - kitty pre-warm: autostarts a hidden `kitty --single-instance --start-as=
#   hidden` at login. Single-instance mode already makes every window after
#   the first fast, but with nothing running yet, the *first* window of a
#   session still pays kitty's cold GPU-context startup cost (~270ms
#   measured). A hidden warm instance from login means there's never a
#   genuine "first" window from the user's perspective - measured ~29ms
#   even opening on a completely empty desktop.
# - plasmalust-resize KWin script: Meta+Shift+Arrow resizes the active
#   window (Hyprland-style), floating or tiled. Frees up Meta+Shift+Left/
#   Right from KWin's built-in "move window to next/previous screen"
#   (rarely used on a single-screen laptop) - like the yazi shortcut
#   above, live reassignment of an already-loaded KWin shortcut doesn't
#   take effect until next login even via direct kglobalaccel DBus calls,
#   confirmed by testing; it's saved correctly either way.
# - Wallpaper overlay: a fullscreen wallpaper browser (click to apply,
#   hover to delete), bound to Meta+O. It's just wallust-templated QML run
#   directly via `qml6` - no build/install step, regenerates every
#   set-theme run (see templates/wallpaper-overlay.qml and the sed step in
#   set-theme that fills in the real $HOME, since unlike the plasma-widgets
#   this isn't installed through install-widgets.sh's own sed).
# - Menu overlay: standalone popup twin of the plasmalust-menu desktop
#   widget (same app/toybox/power items), bound to Meta+X. The widget
#   itself opens its menu via a plain QQC2.Menu.popup() call with no
#   Plasmoid.expanded hook, so there's no way to trigger that specific
#   running widget instance from an external global shortcut - same
#   wallust-templated-QML-via-qml6 approach as the wallpaper overlay
#   instead, sharing the sed step above for the same reason.
# - plasmalust-shortcuts KWin script: registers Meta+X/O/E (menu overlay,
#   wallpaper overlay, yazi) as declarative ShortcutHandlers instead of the
#   standard kglobalshortcutsrc "_launch" desktop-file mechanism used for
#   kitty's Meta+T. That mechanism was tried first for all three and
#   looked entirely correct - kglobalaccel showed each one registered,
#   active, with the right keycode, and invoking it over D-Bus launched
#   the app fine - but after a real logout/login the physical keypress
#   never reached kglobalaccel, meaning kwin_wayland's own compositor-side
#   key grab wasn't in sync with kglobalaccel's registry for these
#   specific entries. KWin-script ShortcutHandlers don't go through that
#   path (already proven reliable for the Meta+Shift+Arrow resize
#   shortcuts), so this runs the same launch commands through one of
#   those instead, via the same executable DataSource pattern the popups
#   already use internally to shell out.
# - krohnkite: adds the qml6 resourceClass (org.qt-project.qml, shared by
#   both overlay popups above) to krohnkite's own ignoreClass config, so it
#   never manages these windows at all - not tiled, not floated-and-
#   resized either. floatingClass was tried first: krohnkite still
#   captures a "floatGeometry" snapshot for floated windows and re-commits
#   it on every layout pass, and that snapshot is taken from the window's
#   still-negotiating initial Wayland geometry (before the popup's real
#   content size settles), so it forced the popup to a wrong, large,
#   half-workarea size every time. ignoreClass skips krohnkite's window
#   management entirely (confirmed via its manage() function, gated on
#   window.shouldIgnore), leaving sizing purely up to the QML client -
#   which is what a small popup needs. Before making non-resizable, this
#   was also tried, which raced krohnkite's tile-vs-float decision against
#   the popup's content layout settling.
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

# 6. kitty pre-warm autostart (see note above)
mkdir -p "$HOME/.config/autostart"
cp "$SCRIPT_DIR/../dotfiles/kitty-prewarm-autostart.desktop" "$HOME/.config/autostart/kitty-prewarm.desktop"
pgrep -x kitty >/dev/null || (kitty --single-instance --start-as=hidden &>/dev/null & disown)

# 7. plasmalust-resize KWin script (see note above)
kpackagetool6 --type KWin/Script --upgrade "$SCRIPT_DIR/../kwin-scripts/plasmalust-resize" 2>/dev/null \
    || kpackagetool6 --type KWin/Script --install "$SCRIPT_DIR/../kwin-scripts/plasmalust-resize"
kwriteconfig6 --file kwinrc --group Plugins --key plasmalust-resizeEnabled --type bool true
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Next Screen" "none,Meta+Shift+Right,Move Window to Next Screen"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Previous Screen" "none,Meta+Shift+Left,Move Window to Previous Screen"
qdbus6 org.kde.KWin /KWin reconfigure

# 8. Wallpaper overlay (see note above)
install -m755 "$SCRIPT_DIR/../scripts/plasmalust-wallpaper-overlay" "$HOME/.local/bin/plasmalust-wallpaper-overlay"
cp "$SCRIPT_DIR/../dotfiles/plasmalust-wallpaper-overlay.desktop" "$HOME/.local/share/applications/plasmalust-wallpaper-overlay.desktop"
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

# 9. Menu overlay (see note above)
install -m755 "$SCRIPT_DIR/../scripts/plasmalust-menu-overlay" "$HOME/.local/bin/plasmalust-menu-overlay"
cp "$SCRIPT_DIR/../dotfiles/plasmalust-menu-overlay.desktop" "$HOME/.local/share/applications/plasmalust-menu-overlay.desktop"
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

# 10. plasmalust-shortcuts KWin script: Meta+X/O/E (see note above)
kpackagetool6 --type KWin/Script --upgrade "$SCRIPT_DIR/../kwin-scripts/plasmalust-shortcuts" 2>/dev/null \
    || kpackagetool6 --type KWin/Script --install "$SCRIPT_DIR/../kwin-scripts/plasmalust-shortcuts"
kwriteconfig6 --file kwinrc --group Plugins --key plasmalust-shortcutsEnabled --type bool true
qdbus6 org.kde.KWin /KWin reconfigure

# 11. krohnkite: fully ignore the qml6 popup overlays instead of managing
# them (see note above). Krohnkite's own built-in default ignore list is
# used as the baseline if the key isn't set yet, so this doesn't clobber
# it - kwriteconfig6 always writes an explicit value, which would
# otherwise silently take over from krohnkite's hardcoded JS fallback.
KROHNKITE_DEFAULT_IGNORE="krunner,yakuake,spectacle,kded5,xwaylandvideobridge,plasmashell,ksplashqml,org.kde.plasmashell,org.kde.polkit-kde-authentication-agent-1,org.kde.kruler,kruler,kwin_wayland,ksmserver-logout-greeter"
EXISTING_IGNORE_CLASS=$(kreadconfig6 --file kwinrc --group "Script-krohnkite" --key "ignoreClass")
if [ -z "$EXISTING_IGNORE_CLASS" ]; then
    EXISTING_IGNORE_CLASS="$KROHNKITE_DEFAULT_IGNORE"
fi
if [[ ",$EXISTING_IGNORE_CLASS," != *",org.qt-project.qml,"* ]]; then
    kwriteconfig6 --file kwinrc --group "Script-krohnkite" --key "ignoreClass" "$EXISTING_IGNORE_CLASS,org.qt-project.qml"
fi
qdbus6 org.kde.KWin /KWin reconfigure

echo "System polish applied. Run set-theme once to render Kvantum's wallust colors,"
echo "then restart plasmashell/relaunch Dolphin and Spotify to pick everything up."
