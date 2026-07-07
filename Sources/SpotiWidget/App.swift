import SwiftUI
import AppKit
import ServiceManagement

@main
struct SpotiWidgetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var spotify = SpotifyController()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(spotify)
        } label: {
            MenuBarLabel()
                .environmentObject(spotify)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Hides the Dock icon so the app lives only in the menu bar.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        registerLoginItem()
    }

    /// Registers the app to open automatically at login, so a plain
    /// drag-to-Applications install (via the DMG) still auto-starts — no script
    /// needed. Idempotent; users can toggle it in System Settings › Login Items.
    private func registerLoginItem() {
        let service = SMAppService.mainApp
        guard service.status != .enabled else { return }
        do {
            try service.register()
        } catch {
            FileHandle.standardError.write(Data("[SpotiWidget] login item register failed: \(error)\n".utf8))
        }
    }
}

/// The compact view shown in the menu bar itself: song name on top (larger),
/// artist below (smaller, dimmed), stacked to keep the item narrow so it
/// doesn't crowd the other menu bar widgets. Uses the system font.
///
/// `MenuBarExtra` sizes the item to its content, so each line is truncated as a
/// string to cap the width.
struct MenuBarLabel: View {
    @EnvironmentObject private var spotify: SpotifyController

    var body: some View {
        if spotify.isRunning, !spotify.title.isEmpty {
            Image(nsImage: MenuBarLabel.render(title: spotify.title, artist: spotify.artist))
        } else {
            Image(nsImage: MenuBarLabel.spotifyGlyph)
        }
    }

    /// The Spotify logo, shown when nothing is playing. Rather than hand-draw it,
    /// we lift the real green mark out of the installed Spotify app icon by
    /// scaling it up and clipping to a circle (which drops the black app tile).
    static let spotifyGlyph: NSImage = {
        let icon = NSWorkspace.shared.icon(forFile: "/Applications/Spotify.app")
        let px: CGFloat = 64                     // render high-res, then display at 16pt
        let image = NSImage(size: NSSize(width: px, height: px))
        image.lockFocus()
        NSGraphicsContext.current!.imageInterpolation = .high
        let rect = CGRect(x: 0, y: 0, width: px, height: px)
        NSBezierPath(ovalIn: rect.insetBy(dx: px * 0.01, dy: px * 0.01)).addClip()
        let d = px * 1.7                          // enlarge so the green circle fills the frame
        icon.draw(in: CGRect(x: (px - d) / 2, y: (px - d) / 2, width: d, height: d))
        image.unlockFocus()
        image.size = NSSize(width: 16, height: 16)
        return image
    }()

    /// Hard cap on the menu bar item width (points) so a long song can never
    /// grow wide enough to push other menu bar widgets (e.g. weather) off-screen.
    /// Your menu bar is nearly full, so this is kept small; raise it if you free
    /// up space by removing other items.
    private static let maxWidth: CGFloat = 140

    /// Trims a string until it (plus an ellipsis) fits within `maxWidth` for the
    /// given font. Bounds the item by actual rendered width, not character count.
    private static func fit(_ s: String, font: NSFont) -> String {
        let t = s.trimmingCharacters(in: .whitespaces)
        func width(_ str: String) -> CGFloat {
            NSAttributedString(string: str, attributes: [.font: font]).size().width
        }
        if width(t) <= maxWidth { return t }
        var trimmed = t
        while trimmed.count > 1, width(trimmed + "…") > maxWidth {
            trimmed = String(trimmed.dropLast())
        }
        return trimmed.trimmingCharacters(in: .whitespaces) + "…"
    }

    /// Draws song (top, larger) over artist (bottom, smaller, dimmed) into a
    /// template image sized to the menu bar height, so both lines always fit.
    /// Template + alpha keeps it tinting correctly in light/dark menu bars.
    private static var cache: [String: NSImage] = [:]

    static func render(title: String, artist: String) -> NSImage {
        let key = title + "\u{1}" + artist
        if let cached = cache[key] { return cached }

        let titleFont = NSFont.systemFont(ofSize: 10, weight: .semibold)
        let artistFont = NSFont.systemFont(ofSize: 7.5, weight: .regular)
        let titleAttr = NSAttributedString(string: fit(title, font: titleFont), attributes: [
            .font: titleFont,
            .foregroundColor: NSColor(white: 0, alpha: 1.0),
        ])
        let artistAttr = NSAttributedString(string: fit(artist, font: artistFont), attributes: [
            .font: artistFont,
            .foregroundColor: NSColor(white: 0, alpha: 0.55),
        ])

        let titleSize = titleAttr.size()
        let artistSize = artistAttr.size()
        let height = NSStatusBar.system.thickness
        let width = ceil(max(titleSize.width, artistSize.width)) + 2
        let contentH = titleSize.height + artistSize.height
        let bottom = ((height - contentH) / 2).rounded()

        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        // AppKit origin is bottom-left, so the artist (lower line) draws first.
        // Both lines are centered horizontally within the item width.
        artistAttr.draw(at: NSPoint(x: (width - artistSize.width) / 2, y: bottom))
        titleAttr.draw(at: NSPoint(x: (width - titleSize.width) / 2, y: bottom + artistSize.height - 1))
        image.unlockFocus()
        image.isTemplate = true

        cache[key] = image
        if cache.count > 24 { cache.removeAll() }
        return image
    }
}
