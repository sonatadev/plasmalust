#!/bin/bash
# Runs as root via the pacman PostTransaction hook (spicetify-reapply.hook).
# Spotify's post-update app files are unpatched by the update, silently
# reverting the wallust theme until spicetify is re-run. Re-apply it as
# whoever owns the (spicetify-chowned) Spotify Apps dir, rather than
# hardcoding a username - keeps this portable across machines/users.
set -euo pipefail

SPOTIFY_APPS="/opt/spotify/Apps"
[ -d "$SPOTIFY_APPS" ] || exit 0

TARGET_USER="$(stat -c '%U' "$SPOTIFY_APPS")"
[ "$TARGET_USER" != "root" ] || exit 0

pkill -u "$TARGET_USER" -x spotify 2>/dev/null || true
sleep 1
runuser -u "$TARGET_USER" -- spicetify backup apply
