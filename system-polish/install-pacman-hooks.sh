#!/bin/bash
# Installs pacman hooks that need root - kept separate from
# apply-system-polish.sh (which runs entirely as a regular user).
#
# spicetify-reapply: Spotify auto-updates overwrite spicetify's patched
# app files, silently reverting the wallust theme until `spicetify backup
# apply` is re-run by hand. This hook does that automatically right after
# every `spotify` package upgrade, so the theme never has to be manually
# brought back again.
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo." >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install -m755 "$SCRIPT_DIR/pacman-hooks/spicetify-reapply-hook.sh" /usr/local/bin/spicetify-reapply-hook.sh
install -m644 "$SCRIPT_DIR/pacman-hooks/spicetify-reapply.hook" /etc/pacman.d/hooks/spicetify-reapply.hook

echo "Pacman hook installed: Spotify updates will now automatically re-apply the spicetify theme."
