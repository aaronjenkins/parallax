# Parallax

<img width="441" height="368" alt="Parallax-v1-screenshot" src="https://github.com/user-attachments/assets/e1d1c5e7-b947-4e7d-b7bc-01ef44c11840" />

A lightweight macOS menubar app for saving and switching between monitor arrangements with one click.

## Download

**[Latest Release (v1.0.0)](https://github.com/aaronjenkins/parallax/releases/latest)**

Install via Homebrew:

```sh
brew tap aaronjenkins/parallax
brew install --cask parallax
```

## What It Does

Parallax sits in your menubar and lets you save your current display configuration as a named profile, then switch between profiles instantly. Useful when you regularly change how your monitors are arranged — for example, laptop below an external display versus laptop beside it.

## Features

- **Save display arrangements** — capture the current position, resolution, and layout of all connected displays as a named profile
- **One-click switching** — apply a saved profile from the menubar to reposition and reconfigure your displays
- **Global hotkeys** — assign `⌃⌥1` through `⌃⌥9` to profiles for keyboard-driven switching
- **Visual preview** — see a diagram of any saved profile's display layout before applying
- **Display detection** — automatically detects connected displays and refreshes when monitors are plugged in or removed
- **Launch at login** — optional auto-start via macOS native `SMAppService`
- **Profile management** — rename, delete, and assign shortcuts from the menubar

## Requirements

- macOS 13 (Ventura) or later
- Accessibility permission (required for global hotkeys — macOS will prompt on first launch)

## Building

1. Open `Parallax.xcodeproj` in Xcode
2. Select the Parallax scheme
3. Build and run (`⌘R`)

If you modify the project structure or add files, regenerate the Xcode project:

```sh
brew install xcodegen  # if not already installed
xcodegen generate
```

## Usage

1. Arrange your displays in System Settings the way you want them
2. Click the Parallax menubar icon (the display icon)
3. Select **Save Current Arrangement...** and give it a name
4. Repeat for each layout you use
5. Switch between profiles by clicking them in the menu, or assign hotkeys via each profile's submenu

## How It Works

Parallax uses public CoreGraphics APIs to read and apply display configurations:

- `CGGetActiveDisplayList` / `CGDisplayBounds` / `CGDisplayCopyDisplayMode` to read current state
- `CGBeginDisplayConfiguration` / `CGConfigureDisplayOrigin` / `CGConfigureDisplayWithDisplayMode` / `CGCompleteDisplayConfiguration` to apply saved profiles
- Displays are identified persistently across reboots using `(vendor, model, serial)` tuples rather than `CGDirectDisplayID`, which can change

Profiles are stored as JSON in `~/Library/Application Support/Parallax/profiles.json`.

## Limitations

- **Identical monitors** — two monitors of the exact same make and model with serial number 0 may not be distinguished reliably. This is rare.
- **Accessibility permission** — global hotkeys require an Accessibility grant in System Settings > Privacy & Security > Accessibility. The app functions without it, but hotkeys will not work.

## Attribution

<a href="https://www.flaticon.com/free-icons/parallax" title="parallax icons">Parallax icons created by Freepik - Flaticon</a>

## License

MIT
