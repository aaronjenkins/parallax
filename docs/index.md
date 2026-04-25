# Parallax

A lightweight macOS menubar app for saving and switching between monitor arrangements with one click. Sits in the menubar, lets you save display configurations as named profiles, and switch between them instantly.

**Download:** [Latest Release](https://github.com/aaronjenkins/parallax/releases/latest) (v1.1.0)

```sh
brew tap aaronjenkins/parallax
brew install --cask parallax
```

| Detail | Value |
|---|---|
| Repo | [github.com/aaronjenkins/parallax](https://github.com/aaronjenkins/parallax) |
| Homebrew tap | [github.com/aaronjenkins/homebrew-parallax](https://github.com/aaronjenkins/homebrew-parallax) |
| Local | `~/code-projects/parallax` |
| Language | Swift (pure macOS SDK, no dependencies) |
| Min OS | macOS 13 (Ventura) |
| Distribution | Direct (notarized), Homebrew Cask |
| Current release | v1.1.0 |

## Features

- Save display arrangements as named profiles
- One-click switching from menubar
- Global hotkeys (`⌃⌥1` through `⌃⌥9`)
- Visual preview of saved layouts
- Auto-detect display connect/disconnect
- Launch at login via `SMAppService`
- Custom profile icons (added in v1.1.0)
- CLI companion for scripted switching (v1.1.0)

## How It Works

Uses public CoreGraphics APIs:
- `CGGetActiveDisplayList` / `CGDisplayBounds` / `CGDisplayCopyDisplayMode` to read state
- `CGBeginDisplayConfiguration` / `CGConfigureDisplayOrigin` / `CGConfigureDisplayWithDisplayMode` / `CGCompleteDisplayConfiguration` to apply
- Displays identified by `(vendor, model, serial)` tuples (survives reboots)
- Profiles stored as JSON in `~/Library/Application Support/Parallax/profiles.json`

## Building

```bash
cd ~/code-projects/parallax
open Parallax.xcodeproj   # Build and run in Xcode (⌘R)

# Regenerate Xcode project if needed
brew install xcodegen
xcodegen generate
```

## Release pipeline

GitHub Actions workflow (`.github/workflows/release.yml`) builds, code-signs with the Developer ID cert, and notarizes via Apple's notary service on tag push. The workflow also updates the Homebrew cask checksum in the `homebrew-parallax` tap repo after the release.

## Architecture

```
Parallax/
  Sources/
    App/          — @main, NSApplicationDelegate, LSUIElement
    MenuBar/      — NSStatusItem, menu construction
    Display/      — CoreGraphics wrapper, display identification, profiles
    Persistence/  — JSON profile store
    Util/         — Display change monitor callback
  Parallax.xcodeproj
  project.yml     — XcodeGen project spec
```

## Key Technical Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Distribution | Direct (notarized) | CG display config APIs require no sandbox |
| Menu framework | AppKit `NSMenu` | Dynamic sections, reliable on macOS 13 |
| Persistence | JSON via `Codable` | Simple, human-readable |
| Display matching | `(vendor, model, serial)` tuple | Survives reboots unlike `CGDirectDisplayID` |
| Min deployment | macOS 13 | Covers 95%+ of active Macs, gets `SMAppService` |

## Distribution Status

Shipped v1.1.0 via Developer ID personal cert + GitHub Actions signing/notarization. Homebrew Cask is the recommended install path for LAN users.

## Tasks

- [ ] Track crash reports from notarization telemetry
- [ ] Decide whether to advertise publicly or keep it a personal-plus-friends tool
