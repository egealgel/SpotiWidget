# SpotiWidget

A lightweight **macOS menu bar widget for Spotify**, written in native Swift +
SwiftUI (`MenuBarExtra`). It controls the Spotify desktop app over AppleScript —
no login, no API keys, no Spotify Premium requirement for playback control.

## Screenshots

<img width="651" height="35" alt="Ekran Resmi 2026-07-07 17 20 50" src="https://github.com/user-attachments/assets/6c0076f4-9609-4fef-9810-40a75a74720e" />

<img width="301" height="512" alt="Ekran Resmi 2026-07-07 17 21 06" src="https://github.com/user-attachments/assets/6c47255c-5ee7-4882-8ee3-eded5ab64a03" />



## Features

-  **Now playing** — song, artist, album, and album artwork
-  **Playback controls** — play/pause, next, previous (instant, optimistic UI)
-  **Seekable progress bar** with elapsed / total time (live scrubbing)
-  **Volume slider** (live)
-  **Album-coloured gradient** background that cross-fades per track
-  Menu-bar-only (no Dock icon); shows the Spotify logo when nothing is playing
-  Lightweight — ~13 MB, ~0% CPU when idle

## Requirements

- macOS 13 (Ventura) or later
- The **Spotify desktop app** installed and running
- Swift toolchain (comes with Xcode or the Xcode Command Line Tools)

## Install (recommended)

```bash
./install.sh
```

This builds a release `.app`, installs it to `~/Applications/SpotiWidget.app`,
code-signs it with a stable identity, and registers a LaunchAgent so it:

- **starts automatically at login**, and
- **restarts itself** if it ever quits (`KeepAlive`).

The first time it controls Spotify, macOS asks for **Automation** permission
(System Settings → Privacy & Security → Automation → allow SpotiWidget → Spotify).
Because the app is signed with a stable identity, you only grant this once.

To remove everything:

```bash
./uninstall.sh
```

## Quick run (development)

```bash
swift run          # build and launch, no install
```

To quit a running instance: click the menu bar icon → the power button.

## Note on "liking" tracks

Saving the current track to your library isn't included, because Spotify's
AppleScript interface has no command for it — that action only exists in the
Spotify Web API (which needs an OAuth flow and a registered developer app). If
you ever want it, it can be added as a separate Web-API layer.

## Project layout

```
Package.swift
Sources/SpotiWidget/
  App.swift               # @main app + MenuBarExtra + menu bar label
  SpotifyController.swift # AppleScript polling & commands (ObservableObject)
  ContentView.swift       # the popover UI
```

## How it works

`SpotifyController` polls Spotify once per second by running an AppleScript via
`osascript` on a background thread, parses the result, and publishes it to the
SwiftUI views. Commands (play/pause, seek, volume, …) are one-line AppleScripts
sent the same way.
