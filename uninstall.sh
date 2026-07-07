#!/bin/bash
#
# Stops SpotiWidget, removes its LaunchAgent and installed app.
#
set -euo pipefail

APP_NAME="SpotiWidget"
BUNDLE_ID="com.spotiwidget.app"
APP_DIR="/Applications/$APP_NAME.app"
AGENT="$HOME/Library/LaunchAgents/$BUNDLE_ID.plist"

echo "==> Unloading agent…"
launchctl unload "$AGENT" 2>/dev/null || true
rm -f "$AGENT"

echo "==> Removing app…"
rm -rf "$APP_DIR"

echo "==> Killing any running instance…"
pkill -f "$APP_DIR/Contents/MacOS/$APP_NAME" 2>/dev/null || true

echo "Done. SpotiWidget uninstalled."
