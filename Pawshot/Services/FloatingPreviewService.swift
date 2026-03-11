import AppKit
import SwiftUI

final class FloatingPreviewService {
    static let shared = FloatingPreviewService()

    private var previewWindow: FloatingPreviewWindow?
    private var dismissTimer: Timer?
    private var remainingTime: TimeInterval = 0
    private var timerStartDate: Date?

    private init() {}

    func show(screenshot: Screenshot, coordinator: CaptureCoordinator) {
        dismiss()

        let window = FloatingPreviewWindow(screenshot: screenshot, coordinator: coordinator)
        window.orderFront(nil)
        previewWindow = window

        let duration = AppSettings.shared.floatingPreviewDuration
        if duration > 0 {
            remainingTime = duration
            startTimer()
        }
    }

    func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        remainingTime = 0
        timerStartDate = nil
        previewWindow?.close()
        previewWindow = nil
    }

    func pauseTimer() {
        guard let startDate = timerStartDate else { return }
        dismissTimer?.invalidate()
        dismissTimer = nil
        let elapsed = Date().timeIntervalSince(startDate)
        remainingTime = max(remainingTime - elapsed, 0)
        timerStartDate = nil
    }

    func resumeTimer() {
        guard remainingTime > 0, dismissTimer == nil else { return }
        startTimer()
    }

    private func startTimer() {
        timerStartDate = Date()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: remainingTime, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }
}
