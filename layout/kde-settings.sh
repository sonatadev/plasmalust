#!/bin/bash
# The plain KDE/KWin settings behind the plasmalust look that aren't
# palette-driven (so not set-theme's job) and aren't panel/widget layout
# (import-layout.py's job): fonts, window decorations, KWin effects and
# tiling, default terminal. Just kwriteconfig6 keys - safe to re-run.
#
# Deliberately NOT included, since they're about one machine's hardware or
# one person's habits rather than the look: Xwayland/display scale, keyboard
# repeat rate, night color, screen locking timeouts.
set -euo pipefail

kw() { kwriteconfig6 "$@"; }

# Fonts: Inter Bold for the UI, JetBrains Mono Nerd Font for monospace.
kw --file kdeglobals --group General --key font "Inter,10,-1,5,700,0,0,0,0,0,0,0,0,0,0,1,Bold,0,0"
kw --file kdeglobals --group General --key menuFont "Inter,10,-1,5,700,0,0,0,0,0,0,0,0,0,0,1,Bold,0,0"
kw --file kdeglobals --group General --key toolBarFont "Inter,10,-1,5,75,0,0,0,0,0,Bold"
kw --file kdeglobals --group General --key smallestReadableFont "Inter,8,-1,5,75,0,0,0,0,0,Bold"
kw --file kdeglobals --group General --key fixed "JetBrainsMono Nerd Font,10,-1,5,700,0,0,0,0,0,0,0,0,0,0,1,Bold,0,0"
kw --file kdeglobals --group WM --key activeFont "Inter,10,-1,5,75,0,0,0,0,Bold"

# kitty as the default terminal (Konsole gets removed by install.sh).
kw --file kdeglobals --group General --key TerminalApplication kitty
kw --file kdeglobals --group General --key TerminalService kitty.desktop
kw --file kglobalshortcutsrc --group services --group kitty.desktop --key _launch "Meta+T"

kw --file kdeglobals --group KDE --key SingleClick true
kw --file kdeglobals --group General --key SingleClick true

# Window decoration buttons: only keep-above / minimize / close, on the right.
kw --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ""
kw --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "AIX"
kw --file kwinrc --group org.kde.kdecoration2 --key BorderSizeAuto --type bool false
kw --file kwinrc --group Windows --key BorderlessMaximizedWindows --type bool false

# KWin effects.
kw --file kwinrc --group Compositing --key AnimationSpeed --type int 3
kw --file kwinrc --group TabBox --key LayoutName coverswitch
for effect in blur coverswitch fade flipswitch scale translucency windowgeometry; do
    kw --file kwinrc --group Plugins --key "${effect}Enabled" --type bool true
done
for effect in glide magiclamp squash wobblywindows desktopchangeosd; do
    kw --file kwinrc --group Plugins --key "${effect}Enabled" --type bool false
done

# Rounded corners (kwin-effect-rounded-corners-git) - outline follows the
# color scheme palette, so it re-themes with set-theme.
kw --file kwinrc --group Plugins --key kwin4_effect_shapecornersEnabled --type bool true
kw --file kwinrc --group Round-Corners --key Size --type int 20
kw --file kwinrc --group Round-Corners --key InactiveCornerRadius --type int 20
kw --file kwinrc --group Round-Corners --key OutlineThickness 4.5
kw --file kwinrc --group Round-Corners --key SecondOutlineThickness 0.25
kw --file kwinrc --group Round-Corners --key InactiveOutlineThickness 3.5
kw --file kwinrc --group Round-Corners --key InactiveSecondOutlineThickness 0.25
kw --file kwinrc --group Round-Corners --key InactiveShadowSize --type int 25
kw --file kwinrc --group Round-Corners --key ActiveOutlineUsePalette --type bool true
kw --file kwinrc --group Round-Corners --key ActiveOutlineUseCustom --type bool false
kw --file kwinrc --group Round-Corners --key ActiveOutlineAlpha --type int 253
kw --file kwinrc --group Round-Corners --key InactiveOutlineUsePalette --type bool true
kw --file kwinrc --group Round-Corners --key InactiveOutlineUseCustom --type bool false
kw --file kwinrc --group Round-Corners --key InactiveOutlinePalette --type int 19
kw --file kwinrc --group Round-Corners --key InactiveOutlineAlpha --type int 255

# Tiling: krohnkite on, Garuda's own polonium/grid-tiling off (they'd fight
# krohnkite over the same windows), 6 virtual desktops in one row.
kw --file kwinrc --group Plugins --key krohnkiteEnabled --type bool true
kw --file kwinrc --group Plugins --key poloniumEnabled --type bool false
kw --file kwinrc --group Plugins --key grid-tilingEnabled --type bool false
for side in Between Bottom Left Right Top; do
    kw --file kwinrc --group Script-krohnkite --key "screenGap$side" --type int 4
done
kw --file kwinrc --group Desktops --key Number --type int 6
kw --file kwinrc --group Desktops --key Rows --type int 1

qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
echo "KDE settings applied."
