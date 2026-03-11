# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

### SPM (primary — no Xcode required)
```bash
swift build                    # debug build
swift build -c release         # release build
swift test                     # run tests (PawshotTests target)
```

### Creating the .app bundle (required for screen capture permission)
```bash
swift build
mkdir -p Pawshot.app/Contents/{MacOS,Resources}
cp .build/debug/Pawshot Pawshot.app/Contents/MacOS/
cp Pawshot/Resources/AppIcon.icns Pawshot.app/Contents/Resources/
# Info.plist must have resolved values (not Xcode variables) — see existing Pawshot.app/Contents/Info.plist
codesign --force --sign - Pawshot.app
open Pawshot.app
```
Ad-hoc signing is required — macOS won't remember screen capture permission for unsigned binaries.

### With Xcode (via XcodeGen)
```bash
brew install xcodegen
xcodegen generate
open Pawshot.xcodeproj
```

## Architecture

**Menu bar-only app** (`LSUIElement=true`) using SwiftUI `MenuBarExtra` + AppKit for capture overlays.

### Key patterns
- **`CaptureCoordinator`** (singleton) — orchestrates all capture flows. Window cleanup is deferred to next run loop via `DispatchQueue.main.async` to avoid destroying NSWindows from within their own event callbacks.
- **`ScreenCaptureEngine`** — uses `SCScreenshotManager` on macOS 14+, falls back to `CGWindowListCreateImage` on macOS 13 (`LegacyCaptureEngine`).
- **`HotkeyService`** — native Carbon `RegisterEventHotKey` with C-compatible function pointer callback (not closures). Default shortcuts: ⌘⇧3/4/5.
- **NSWindow lifecycle** — all overlay windows use `isReleasedWhenClosed = false` and `orderOut(nil)` instead of `close()`.
- **Coordinate systems** — capture overlays and annotation canvas use flipped coordinates (`isFlipped = true`). `AnnotationRenderer` flips context for final render. Text uses `NSGraphicsContext(cgContext:, flipped: true)`.
- **Point vs pixel sizes** — `CaptureService.nsImage(from:)` divides CGImage pixel dimensions by `backingScaleFactor` to get correct point size.

### Layer breakdown
| Layer | Tech | Why |
|-------|------|-----|
| Selection overlays, window picker | Pure AppKit (NSWindow + NSView) | Borderless transparent windows need AppKit |
| Annotation canvas | NSView via NSViewRepresentable | CGContext drawing + precise mouse tracking |
| Toolbar, settings, menu bar | SwiftUI | Declarative UI |
| Hotkeys | Carbon Events | Global shortcuts without library dependencies |

### Services (`Pawshot/Services/`)
- `CaptureService` — converts CGImage → NSImage with correct sizing
- `ClipboardService` — NSPasteboard operations
- `FileExportService` — PNG/JPEG/WebP export via NSSavePanel
- `PermissionService` — `CGPreflightScreenCaptureAccess()` check + prompt
- `FloatingPreviewService` — manages floating thumbnail panel

### Editor (`Pawshot/Editor/`)
- `AnnotationCanvas` — NSViewRepresentable, `isFlipped=true`, draws with `image.draw(respectFlipped: true)`
- `AnnotationRenderer` — CGContext-based render for both canvas preview and final image export. Blur/mosaic use `CIPixellate` filter.
- Tools: arrow, line, rectangle, ellipse, text, highlighter, blur, mosaic, crop

## Important constraints
- **macOS 13+ target** — avoid APIs only available on macOS 14+ (e.g., `SCStreamConfiguration.scaleFactor`, `SettingsLink`). Use `#available` checks where needed.
- **No external dependencies** — `Package.swift` has zero dependencies. Hotkeys use Carbon directly.
- **SPM doesn't compile xcassets into .icns** — the `AppIcon.icns` file in `Resources/` is pre-built via `iconutil` and manually copied into the `.app` bundle.
