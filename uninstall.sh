#!/bin/bash
#
# Stops SpotiWidget, removes the login item, and deletes the app.
#
set -euo pipefail

APP_NAME="SpotiWidget"
BUNDLE_ID="com.spotiwidget.app"
APP_DIR="/Applications/$APP_NAME.app"
LEGACY_AGENT="$HOME/Library/LaunchAgents/$BUNDLE_ID.plist"

echo "==> Removing legacy LaunchAgent (if any)…"
launchctl unload "$LEGACY_AGENT" 2>/dev/null || true
rm -f "$LEGACY_AGENT"

echo "==> Quitting app…"
pkill -f "$APP_DIR/Contents/MacOS/$APP_NAME" 2>/dev/null || true

echo "==> Removing app…"
rm -rf "$APP_DIR"

echo "Done. SpotiWidget uninstalled."
echo "Its Login Items entry (if shown) clears once the app is gone; you can also"
echo "remove it in System Settings › General › Login Items."
