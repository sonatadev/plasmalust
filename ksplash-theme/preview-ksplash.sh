#!/bin/bash
# Stages the current Splash.qml + portrait into this directory (untracked -
# see .gitignore) and previews it with ksplashqml's own test mode, which
# runs in an ordinary window and touches nothing system-wide. No sudo needed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STAGED_QML="$HOME/.cache/wallust/ksplash-Splash.qml"
if [ ! -f "$STAGED_QML" ]; then
    echo "Error: $STAGED_QML not found. Run set-theme first." >&2
    exit 1
fi

mkdir -p "$SCRIPT_DIR/contents/splash/images"
cp "$STAGED_QML" "$SCRIPT_DIR/contents/splash/Splash.qml"

PORTRAIT="$HOME/.cache/wallust/portrait-dither.png"
if [ -f "$PORTRAIT" ]; then
    cp "$PORTRAIT" "$SCRIPT_DIR/contents/splash/images/portrait.png"
else
    echo "Warning: $PORTRAIT not found, previewing without a portrait image." >&2
fi

exec ksplashqml "$SCRIPT_DIR" --test --window
