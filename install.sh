#!/bin/bash
#
# Builds SpotiWidget as a real .app bundle, installs it to ~/Applications,
# and sets up a LaunchAgent so it starts at login and stays running.
#
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="SpotiWidget"
BUNDLE_ID="com.spotiwidget.app"
APP_DIR="/Applications/$APP_NAME.app"
AGENT="$HOME/Library/LaunchAgents/$BUNDLE_ID.plist"

echo "==> Building release binary…"
swift build -c release
BIN="$(swift build -c release --show-bin-path)/$APP_NAME"

echo "==> Assembling $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp Info.plist "$APP_DIR/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP_DIR/Contents/Resources/AppIcon.icns"

echo "==> Code signing (stable ad-hoc identity)…"
# A stable identity keeps macOS from re-asking for Automation permission on every rebuild.
codesign --force --sign - --identifier "$BUNDLE_ID" "$APP_DIR"

echo "==> Installing LaunchAgent…"
mkdir -p "$(dirname "$AGENT")"
cat > "$AGENT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$BUNDLE_ID</string>
    <key>ProgramArguments</key>
    <array>
        <string>$APP_DIR/Contents/MacOS/$APP_NAME</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
PLIST

echo "==> (Re)loading agent…"
launchctl unload "$AGENT" 2>/dev/null || true
launchctl load "$AGENT"

echo ""
echo "Done. $APP_NAME is installed at:"
echo "    $APP_DIR"
echo "It will now launch at login and restart automatically if it quits."
echo "The first time it controls Spotify, allow the Automation prompt."
echo ""
echo "To stop & uninstall:  ./uninstall.sh"
