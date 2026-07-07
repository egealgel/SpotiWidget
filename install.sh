#!/bin/bash
#
# Builds SpotiWidget from source and installs it to /Applications.
# (Most users don't need this — just use the DMG. This is for building from
# source.) The app registers itself to launch at login on first run.
#
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="SpotiWidget"
BUNDLE_ID="com.spotiwidget.app"
APP_DIR="/Applications/$APP_NAME.app"
LEGACY_AGENT="$HOME/Library/LaunchAgents/$BUNDLE_ID.plist"

echo "==> Building release binary…"
swift build -c release
BIN="$(swift build -c release --show-bin-path)/$APP_NAME"

echo "==> Assembling $APP_DIR"
# Remove any old LaunchAgent from previous versions (login-at-start is now
# handled by the app itself via SMAppService).
if [ -f "$LEGACY_AGENT" ]; then
    launchctl unload "$LEGACY_AGENT" 2>/dev/null || true
    rm -f "$LEGACY_AGENT"
fi
pkill -f "$APP_DIR/Contents/MacOS/$APP_NAME" 2>/dev/null || true
sleep 1
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp Info.plist "$APP_DIR/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP_DIR/Contents/Resources/AppIcon.icns"

echo "==> Code signing (stable ad-hoc identity)…"
codesign --force --sign - --identifier "$BUNDLE_ID" "$APP_DIR"

echo "==> Launching…"
open "$APP_DIR"

echo ""
echo "Done. $APP_NAME is installed at $APP_DIR and now runs in the menu bar."
echo "It registered itself to open at login (System Settings › General ›"
echo "Login Items). The first time it controls Spotify, allow the Automation prompt."
echo ""
echo "To uninstall:  ./uninstall.sh"
