# Pawshot

A lightweight, open-source screenshot tool for macOS.

## Features

- **Area Capture** — Select any region of your screen (⌘⇧4)
- **Window Capture** — Click to capture a specific window (⌘⇧5)
- **Full Screen Capture** — Capture the entire screen (⌘⇧3)
- **Floating Preview** — Quick-access thumbnail after capture with Copy / Save / Edit actions
- **Annotation Editor** — Arrow, line, rectangle, ellipse, text, highlighter, blur, mosaic, and crop tools
- **Export** — PNG, JPEG, and WebP formats
- **Menu Bar App** — Lives in your menu bar, no Dock icon

## Requirements

- macOS 13.0+ (Ventura or later)
- Screen Recording permission

## Building

### With Swift Package Manager

```bash
swift build
```

### With Xcode

```bash
# Generate Xcode project (requires xcodegen)
brew install xcodegen
xcodegen generate
open Pawshot.xcodeproj
```

### Creating an App Bundle

```bash
swift build
mkdir -p Pawshot.app/Contents/MacOS
cp .build/debug/Pawshot Pawshot.app/Contents/MacOS/
cp Pawshot/Info.plist Pawshot.app/Contents/MacOS/../Info.plist

# Ad-hoc sign for screen capture permission
codesign --force --sign - Pawshot.app
```

## Usage

1. Launch Pawshot — an icon appears in the menu bar
2. Grant Screen Recording permission in System Settings > Privacy & Security
3. Use keyboard shortcuts or the menu bar to capture:
   - **⌘⇧3** Full Screen
   - **⌘⇧4** Area Selection
   - **⌘⇧5** Window Selection
4. After capture, a floating preview appears — click to Copy, Save, or Edit
5. The annotation editor supports arrows, shapes, text, blur/mosaic, and crop

## Tech Stack

- **Swift** (SwiftUI + AppKit)
- **ScreenCaptureKit** (macOS 14+ with CGWindowListCreateImage fallback for macOS 13)
- **Carbon Events** for global hotkeys

## Project Structure

```
Pawshot/
├── PawshotApp.swift          # @main, MenuBarExtra
├── AppDelegate.swift          # AppKit integration
├── Models/                    # Data models
├── Services/                  # Capture engine, clipboard, export, hotkeys
├── Capture/                   # Selection overlay, window picker
├── Editor/                    # Annotation editor, canvas, renderer
├── UI/                        # Menu bar, settings, floating preview
└── Extensions/                # Helper extensions
```

## License

MIT — see [LICENSE](LICENSE) for details.
