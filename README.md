<p align="center">
  <img src="docs/images/app-icon.png" width="128" height="128" alt="Pawshot icon">
</p>

<h1 align="center">Pawshot</h1>

<p align="center">
  <strong>A lightweight, open-source screenshot tool for macOS.</strong><br>
  Capture, annotate, and share — all from your menu bar.
</p>

<p align="center">
  <a href="README_ja.md">日本語</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS_13+-0A84FF?style=flat-square&logo=apple&logoColor=white" alt="macOS 13+">
  <img src="https://img.shields.io/badge/Swift-5.9+-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift">
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="MIT License">
</p>

---

## Features

- 📸 **Area Capture** — Select any region of your screen (`⌘⇧4`)
- 🪟 **Window Capture** — Click to capture a specific window (`⌘⇧5`)
- 🖥️ **Full Screen Capture** — Capture the entire screen (`⌘⇧3`)
- 🔍 **Floating Preview** — Quick-access thumbnail with Copy / Save / Edit actions
- ✏️ **Annotation Editor** — Arrows, shapes, text, highlighter, blur, mosaic, and crop
- 📤 **Flexible Export** — PNG, JPEG, and WebP formats
- 🔘 **Menu Bar App** — Lives in your menu bar, no Dock clutter

## Screenshots

> _Coming soon._

## Installation

### Homebrew

```bash
brew install nyanko3141592/tap/pawshot
```

### Download

Download the latest `.dmg` from the [Releases](https://github.com/nyanko3141592/Pawshot/releases) page.

## Getting Started

### Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon (arm64)
- Screen Recording permission

### Build with Swift Package Manager

```bash
swift build
```

### Build with Xcode

```bash
# Install xcodegen if you haven't already
brew install xcodegen

# Generate and open the project
xcodegen generate
open Pawshot.xcodeproj
```

### Create an App Bundle

```bash
swift build
mkdir -p Pawshot.app/Contents/MacOS
cp .build/debug/Pawshot Pawshot.app/Contents/MacOS/
cp Pawshot/Info.plist Pawshot.app/Contents/Info.plist

# Ad-hoc sign for screen capture permission
codesign --force --sign - Pawshot.app
```

## Usage

1. **Launch** Pawshot — an icon appears in your menu bar.
2. **Grant permission** — System Settings > Privacy & Security > Screen Recording.
3. **Capture** using keyboard shortcuts or the menu bar icon:

   | Shortcut | Action |
   |----------|--------|
   | `⌘⇧3` | Full Screen |
   | `⌘⇧4` | Area Selection |
   | `⌘⇧5` | Window Selection |

4. A **floating preview** appears — click to Copy, Save, or Edit.
5. The **annotation editor** supports arrows, shapes, text, blur/mosaic, and crop.

## Tech Stack

| Component | Technology |
|-----------|------------|
| UI | SwiftUI + AppKit |
| Capture | ScreenCaptureKit (macOS 14+) with CGWindowListCreateImage fallback |
| Hotkeys | Carbon Events |

## Project Structure

```
Pawshot/
├── PawshotApp.swift        # @main, MenuBarExtra
├── AppDelegate.swift        # AppKit integration
├── Models/                  # Data models
├── Services/                # Capture engine, clipboard, export, hotkeys
├── Capture/                 # Selection overlay, window picker
├── Editor/                  # Annotation editor, canvas, renderer
├── UI/                      # Menu bar, settings, floating preview
└── Extensions/              # Helper extensions
```

## License

MIT — see [LICENSE](LICENSE) for details.
