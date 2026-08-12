#!/bin/bash
# Installs/upgrades all plasmalust desktop widgets, and sets up the
# cava bridge service the visualizer widget depends on. Run from anywhere;
# paths are resolved relative to this script's own location.
#
# The widget QML/config files in this repo use the placeholder
# /home/YOUR_USERNAME/ (so they're safe to publish) - substituted for the
# real $HOME here at install time, into a scratch copy, so the installed
# package actually works on this machine.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR=$(mktemp -d)
trap 'rm -rf "$BUILD_DIR"' EXIT

for widget in plasmalust-sysinfo plasmalust-mediaplayer plasmalust-visualizer plasmalust-procmon plasmalust-wallpicker; do
    cp -r "$SCRIPT_DIR/$widget" "$BUILD_DIR/$widget"
    grep -rl "/home/YOUR_USERNAME" "$BUILD_DIR/$widget" 2>/dev/null | while read -r f; do
        sed -i "s|/home/YOUR_USERNAME|$HOME|g" "$f"
    done || true
    kpackagetool6 --type Plasma/Applet --upgrade "$BUILD_DIR/$widget" 2>/dev/null \
        || kpackagetool6 --type Plasma/Applet --install "$BUILD_DIR/$widget"
done

# Visualizer widget dependency: cava writing raw bar data over a FIFO into a
# plain file the widget polls. See cava-bridge/ for details.
mkdir -p "$HOME/.config/cava" "$HOME/.config/systemd/user" "$HOME/.cache/wallust"
sed "s|/home/YOUR_USERNAME|$HOME|g" "$SCRIPT_DIR/cava-bridge/plasmalust-widget.conf" > "$HOME/.config/cava/plasmalust-widget.conf"
cp "$SCRIPT_DIR/cava-bridge/plasmalust-cava-bridge.service" "$HOME/.config/systemd/user/plasmalust-cava-bridge.service"
install -m755 "$SCRIPT_DIR/cava-bridge/plasmalust-cava-bridge" "$HOME/.local/bin/plasmalust-cava-bridge"
mkfifo "$HOME/.cache/wallust/cava.fifo" 2>/dev/null || true

systemctl --user daemon-reload
systemctl --user enable --now plasmalust-cava-bridge.service

# plasmalust-wallpicker widget dependency: applies a picked wallpaper +
# re-runs set-theme, and keeps its thumbnail cache in sync.
install -m755 "$SCRIPT_DIR/../scripts/plasmalust-set-wallpaper" "$HOME/.local/bin/plasmalust-set-wallpaper"
install -m755 "$SCRIPT_DIR/../scripts/plasmalust-refresh-thumbnails" "$HOME/.local/bin/plasmalust-refresh-thumbnails"
"$HOME/.local/bin/plasmalust-refresh-thumbnails"

echo "Widgets installed. Add them via right-click desktop > Add Widgets > search \"Plasmalust\"."
