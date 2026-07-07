#!/bin/bash
#
# Regenerates Resources/AppIcon.icns — the green Spotify mark lifted from the
# installed Spotify app icon (circle-cropped, same as the menu bar glyph).
#
set -euo pipefail
cd "$(dirname "$0")"

WORK="$(mktemp -d)"
ICONSET="$WORK/SpotiWidget.iconset"
mkdir -p "$ICONSET"

cat > "$WORK/gen.swift" <<'SWIFT'
import AppKit
let iconset = CommandLine.arguments[1]
let icon = NSWorkspace.shared.icon(forFile: "/Applications/Spotify.app")
func render(_ px: CGFloat) -> Data {
    let img = NSImage(size: NSSize(width: px, height: px))
    img.lockFocus()
    NSGraphicsContext.current!.imageInterpolation = .high
    let pad = px * 0.06
    let rect = CGRect(x: pad, y: pad, width: px - 2 * pad, height: px - 2 * pad)
    NSBezierPath(ovalIn: rect).addClip()
    let d = (px - 2 * pad) * 1.7
    icon.draw(in: CGRect(x: (px - d) / 2, y: (px - d) / 2, width: d, height: d))
    img.unlockFocus()
    return NSBitmapImageRep(data: img.tiffRepresentation!)!.representation(using: .png, properties: [:])!
}
let map: [(String, CGFloat)] = [
  ("icon_16x16",16),("icon_16x16@2x",32),("icon_32x32",32),("icon_32x32@2x",64),
  ("icon_128x128",128),("icon_128x128@2x",256),("icon_256x256",256),
  ("icon_256x256@2x",512),("icon_512x512",512),("icon_512x512@2x",1024)
]
for (name, px) in map { try! render(px).write(to: URL(fileURLWithPath: "\(iconset)/\(name).png")) }
SWIFT

swift "$WORK/gen.swift" "$ICONSET"
mkdir -p Resources
iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns
rm -rf "$WORK"
echo "Wrote Resources/AppIcon.icns"
