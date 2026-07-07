import SwiftUI

/// Spotify brand green, used as the accent throughout.
private let spotifyGreen = Color(red: 0.11, green: 0.73, blue: 0.33)

/// Fixed inner content width; the panel is this plus a margin on each side so
/// slider ends, time labels and volume icons always stay inside the edges.
private let contentWidth: CGFloat = 256
private let panelWidth: CGFloat = 288

struct ContentView: View {
    @EnvironmentObject private var spotify: SpotifyController

    var body: some View {
        ZStack {
            // `.equatable()` keeps the background from rebuilding on every slider
            // tick — it only changes when the track (and its colors) change.
            ArtworkGradient(top: spotify.gradientTop, bottom: spotify.gradientBottom, trackKey: spotify.title)
                .equatable()
            Group {
                if spotify.isRunning && !spotify.title.isEmpty {
                    nowPlaying
                } else {
                    idleState
                }
            }
            .frame(width: contentWidth)   // pin content width so nothing overflows
            .padding(.vertical, 18)
            .transition(.opacity)
        }
        .frame(width: panelWidth)
        .clipped() // keep sliding transitions from spilling past the panel edges
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: spotify.title)
        .animation(.easeInOut(duration: 0.6), value: spotify.gradientTop)
        .animation(.easeInOut(duration: 0.25), value: spotify.isRunning)
        .onAppear { spotify.setPopoverOpen(true) }
        .onDisappear { spotify.setPopoverOpen(false) }
    }

    // MARK: - Now playing

    private var nowPlaying: some View {
        VStack(spacing: 14) {
            artwork
                .id(spotify.title)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .opacity
                ))

            VStack(spacing: 3) {
                Text(spotify.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(spotify.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(spotify.album)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .id(spotify.title)
            .transition(.move(edge: .trailing).combined(with: .opacity))

            progressBar
            controls
            volumeBar
        }
    }

    private var artwork: some View {
        Group {
            if let image = spotify.artwork {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color.secondary.opacity(0.15)
                    Image(systemName: "music.note")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 224, height: 224)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 14, y: 8)
    }

    private var progressBar: some View {
        VStack(spacing: 3) {
            Slider(
                value: Binding(
                    get: { spotify.position },
                    set: { spotify.seekLive($0) }
                ),
                in: 0...max(spotify.duration, 1),
                onEditingChanged: { editing in
                    spotify.isScrubbing = editing
                    if !editing { spotify.seek(to: spotify.position) }
                }
            )
            .tint(spotifyGreen)
            HStack {
                Text(timeString(spotify.position))
                Spacer()
                Text(timeString(spotify.duration))
            }
            .font(.caption2)
            .monospacedDigit()
            .foregroundStyle(.secondary)
        }
    }

    private var controls: some View {
        HStack(spacing: 20) {
            ControlButton(system: "backward.fill", size: 16, action: spotify.previous)

            Button(action: spotify.playPause) {
                ZStack {
                    Circle().fill(spotifyGreen)
                        .frame(width: 54, height: 54)
                        .shadow(color: spotifyGreen.opacity(0.5), radius: 8, y: 3)
                    Image(systemName: spotify.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .id(spotify.isPlaying)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
            }
            .buttonStyle(PressableButtonStyle())
            .animation(.spring(response: 0.3, dampingFraction: 0.55), value: spotify.isPlaying)

            ControlButton(system: "forward.fill", size: 16, action: spotify.next)
        }
        .padding(.vertical, 2)
    }

    private var volumeBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.fill")
                .foregroundStyle(.secondary)
                .font(.caption)
            Slider(
                value: Binding(
                    get: { spotify.volume },
                    set: { spotify.setVolumeLive($0) }
                ),
                in: 0...100,
                onEditingChanged: { editing in
                    spotify.isAdjustingVolume = editing
                    if !editing { spotify.setVolume(spotify.volume) }
                }
            )
            .tint(spotifyGreen)
            Image(systemName: "speaker.wave.3.fill")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }

    // MARK: - Idle

    private var idleState: some View {
        VStack(spacing: 14) {
            Image(systemName: "music.note")
                .font(.system(size: 40))
                .foregroundStyle(spotifyGreen)
            Text(spotify.isRunning ? "Nothing playing" : "Spotify isn't running")
                .font(.headline)
                .foregroundStyle(.secondary)
            if !spotify.isRunning {
                Button("Open Spotify") { spotify.openSpotify() }
                    .buttonStyle(.borderedProminent)
                    .tint(spotifyGreen)
            }
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
    }

    private func timeString(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

// MARK: - Reusable controls

/// A round transport button that highlights on hover and dips on press.
private struct ControlButton: View {
    let system: String
    let size: CGFloat
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: size * 2.4, height: size * 2.4)
                .background(
                    Circle().fill(Color.primary.opacity(hovering ? 0.12 : 0))
                )
                .contentShape(Circle())
        }
        .buttonStyle(PressableButtonStyle())
        .onHover { h in
            withAnimation(.easeOut(duration: 0.15)) { hovering = h }
        }
    }
}

/// A smooth gradient built from the album's dominant color, with a subtle dark
/// scrim toward the bottom so the controls and text stay legible. Equatable on
/// the track + colors so it isn't rebuilt on every progress/volume update.
private struct ArtworkGradient: View, Equatable {
    let top: Color
    let bottom: Color
    let trackKey: String

    static func == (lhs: ArtworkGradient, rhs: ArtworkGradient) -> Bool {
        lhs.trackKey == rhs.trackKey && lhs.top == rhs.top && lhs.bottom == rhs.bottom
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [top, bottom], startPoint: .topLeading, endPoint: .bottomTrailing)
            LinearGradient(colors: [.clear, .black.opacity(0.35)], startPoint: .center, endPoint: .bottom)
        }
        .frame(width: panelWidth)
        .clipped()
    }
}

/// Scales the label down with a spring while pressed for a tactile feel.
private struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.86 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.55), value: configuration.isPressed)
    }
}
