import AppKit
import ScreenCaptureKit
import SwiftUI

final class CaptureCoordinator: ObservableObject {
    static let shared = CaptureCoordinator()

    @Published var lastScreenshot: Screenshot?
    @Published var isCapturing = false
    @Published var screenshotHistory: [Screenshot] = []
    private let maxHistoryItems = 10

    /// When true, area selection completes with OCR instead of normal capture
    var pendingOCR = false

    private let captureService = CaptureService()
    private var selectionWindows: [SelectionOverlayWindow] = []
    private var windowPickerOverlay: WindowPickerOverlay?

    private init() {}

    func startCapture(mode: CaptureMode) {
        guard !isCapturing else { return }

        Task { @MainActor in
            guard await PermissionService.shared.checkAndPromptIfNeeded() else { return }

            switch mode {
            case .fullScreen:
                await captureFullScreen()
            case .area:
                pendingOCR = false
                showSelectionOverlay()
            case .window:
                showWindowPicker()
            case .ocrText:
                pendingOCR = true
                showSelectionOverlay()
            }
        }
    }

    @MainActor
    private func captureFullScreen() async {
        isCapturing = true
        defer { isCapturing = false }

        // Brief delay to let menu close
        try? await Task.sleep(nanoseconds: 200_000_000)

        do {
            let screenshot = try await captureService.captureFullScreen()
            handleCaptureResult(screenshot)
        } catch {
            print("Full screen capture failed: \(error)")
        }
    }

    @MainActor
    func showSelectionOverlay() {
        isCapturing = true
        dismissOverlays()

        for screen in NSScreen.screens {
            let window = SelectionOverlayWindow(screen: screen, coordinator: self)
            window.makeKeyAndOrderFront(nil)
            selectionWindows.append(window)
        }
    }

    @MainActor
    func showWindowPicker() {
        isCapturing = true
        dismissOverlays()

        let overlay = WindowPickerOverlay()
        overlay.show()
        windowPickerOverlay = overlay
    }

    @MainActor
    func completeAreaCapture(rect: CGRect, screen: NSScreen) {
        let isOCR = pendingOCR
        pendingOCR = false
        dismissOverlays()

        Task {
            do {
                let displays = try await WindowDiscoveryService.shared.displays()
                guard let display = displays.first(where: { $0.displayID == screen.displayID }) else {
                    isCapturing = false
                    return
                }

                // Convert from screen coordinates to display coordinates
                let flippedRect = CGRect(
                    x: rect.origin.x - screen.frame.origin.x,
                    y: screen.frame.height - rect.origin.y - rect.height + screen.frame.origin.y,
                    width: rect.width,
                    height: rect.height
                )

                let screenshot = try await captureService.captureArea(
                    display: display,
                    rect: flippedRect,
                    pixelScale: screen.backingScaleFactor
                )

                if isOCR {
                    handleOCRResult(screenshot)
                } else {
                    handleCaptureResult(screenshot)
                }
            } catch {
                print("Area capture failed: \(error)")
            }
            isCapturing = false
        }
    }

    @MainActor
    private func handleOCRResult(_ screenshot: Screenshot) {
        Task {
            let success = await OCRService.shared.recognizeTextAndCopy(from: screenshot.image)
            if success {
                if AppSettings.shared.playCaptureSound {
                    NSSound(named: "Tink")?.play()
                }
            } else {
                NSSound.beep()
            }
        }
    }

    @MainActor
    func completeWindowCapture(window: SCWindow) {
        dismissOverlays()

        Task {
            do {
                let screenshot = try await captureService.captureWindow(window)
                handleCaptureResult(screenshot)
            } catch {
                print("Window capture failed: \(error)")
            }
            isCapturing = false
        }
    }

    @MainActor
    func cancelCapture() {
        dismissOverlays()
        isCapturing = false
    }

    @MainActor
    private func dismissOverlays() {
        // Defer cleanup to next run loop iteration to avoid
        // destroying windows from within their own event callbacks
        let windows = selectionWindows
        let picker = windowPickerOverlay
        selectionWindows.removeAll()
        windowPickerOverlay = nil

        DispatchQueue.main.async {
            picker?.dismiss()
            windows.forEach { $0.orderOut(nil) }
        }
    }

    func clearHistory() {
        screenshotHistory.removeAll()
    }

    @MainActor
    private func handleCaptureResult(_ screenshot: Screenshot) {
        lastScreenshot = screenshot

        // Add to history
        screenshotHistory.insert(screenshot, at: 0)
        if screenshotHistory.count > maxHistoryItems {
            screenshotHistory.removeLast()
        }

        if AppSettings.shared.copyToClipboard {
            ClipboardService.shared.copyToClipboard(screenshot.image)
        }

        if AppSettings.shared.saveToFile {
            let format = AppSettings.shared.selectedExportFormat
            _ = try? FileExportService.shared.save(screenshot.image, format: format)
        }

        if AppSettings.shared.showFloatingPreview {
            FloatingPreviewService.shared.show(screenshot: screenshot, coordinator: self)
        }

        if AppSettings.shared.playCaptureSound {
            NSSound(named: "Tink")?.play()
        }
    }

    func openEditor(for screenshot: Screenshot) {
        let controller = EditorWindowController(screenshot: screenshot)
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        controller.window?.makeKeyAndOrderFront(nil)
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return deviceDescription[key] as? CGDirectDisplayID ?? 0
    }
}
