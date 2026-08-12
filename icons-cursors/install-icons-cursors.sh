#!/bin/bash
# One-time install for the icon theme (Papirus-Dark) and cursor theme
# (Bibata-Modern, all three color variants) that set-theme picks between
# automatically based on the current wallust accent. Interactive - AUR
# builds (papirus-folders, bibata-cursor-theme) will prompt normally.
set -euo pipefail

paru -S --needed papirus-icon-theme papirus-folders bibata-cursor-theme

echo "Done. Re-run set-theme to apply icon/cursor colors matching the current wallpaper."
