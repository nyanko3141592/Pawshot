import AppKit
import SwiftUI

final class FloatingPreviewService {
    static let shared = FloatingPreviewService()

    private var previewItems: [PreviewItem] = []
    private let maxVisiblePreviews = 5
    private let previewSpacing: CGFloat = 8.0
    private let screenMargin: CGFloat = 16.0

    private init() {}

    func show(screenshot: Screenshot, coordinator: CaptureCoordinator) {
        let id = UUID()
        let window = FloatingPreviewWindow(screenshot: screenshot, coordinator: coordinator, previewID: id)

        let item = PreviewItem(
            id: id,
            screenshot: screenshot,
            coordinator: coordinator,
            window: window
        )

        previewItems.append(item)

        // Enforce max visible previews — dismiss oldest
        while previewItems.count > maxVisiblePreviews {
            let oldest = previewItems[0]
            removeSilently(id: oldest.id)
        }

        repositionAllPreviews(animated: false)
        window.orderFront(nil)
    }

    func dismiss(id: UUID) {
        guard let index = previewItems.firstIndex(where: { $0.id == id }) else { return }
        let item = previewItems.remove(at: index)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            item.window.animator().alphaValue = 0
        }, completionHandler: {
            item.window.orderOut(nil)
        })

        repositionAllPreviews(animated: true)
    }

    func dismissAll() {
        for item in previewItems {
            item.window.orderOut(nil)
        }
        previewItems.removeAll()
    }

    private func removeSilently(id: UUID) {
        guard let index = previewItems.firstIndex(where: { $0.id == id }) else { return }
        let item = previewItems.remove(at: index)
        item.window.orderOut(nil)
    }

    private func repositionAllPreviews(animated: Bool) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame

        var currentY = screenFrame.minY + screenMargin

        for item in previewItems {
            let size = item.window.frame.size
            let origin = NSPoint(
                x: screenFrame.maxX - size.width - screenMargin,
                y: currentY
            )

            if animated {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.25
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    item.window.animator().setFrameOrigin(origin)
                }
            } else {
                item.window.setFrameOrigin(origin)
            }

            currentY += size.height + previewSpacing
        }
    }
}

final class PreviewItem {
    let id: UUID
    let screenshot: Screenshot
    weak var coordinator: CaptureCoordinator?
    let window: FloatingPreviewWindow

    init(id: UUID, screenshot: Screenshot, coordinator: CaptureCoordinator, window: FloatingPreviewWindow) {
        self.id = id
        self.screenshot = screenshot
        self.coordinator = coordinator
        self.window = window
    }
}
