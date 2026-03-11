import AppKit
import SwiftUI

final class FloatingPreviewService {
    static let shared = FloatingPreviewService()

    private var previewWindow: FloatingPreviewWindow?
    private var dismissTimer: Timer?

    private init() {}

    func show(screenshot: Screenshot, coordinator: CaptureCoordinator) {
        dismiss()

        let window = FloatingPreviewWindow(screenshot: screenshot, coordinator: coordinator)
        window.orderFront(nil)
        previewWindow = window

        let duration = AppSettings.shared.floatingPreviewDuration
        if duration > 0 {
            dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                self?.dismiss()
            }
        }
    }

    func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        previewWindow?.close()
        previewWindow = nil
    }
}
