import AppKit
import SwiftUI

final class FloatingPreviewWindow: NSPanel {
    init(screenshot: Screenshot, coordinator: CaptureCoordinator) {
        let imageSize = screenshot.image.size  // Already in points
        let maxWidth: CGFloat = 200
        let maxHeight: CGFloat = 140
        let scale = min(maxWidth / max(imageSize.width, 1), maxHeight / max(imageSize.height, 1), 1.0)
        let previewSize = NSSize(
            width: ceil(imageSize.width * scale),
            height: ceil(imageSize.height * scale)
        )

        super.init(
            contentRect: NSRect(origin: .zero, size: previewSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovableByWindowBackground = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.animationBehavior = .utilityWindow
        self.isReleasedWhenClosed = false

        let previewView = FloatingPreviewView(
            screenshot: screenshot,
            coordinator: coordinator,
            previewSize: previewSize
        )
        let hostingView = NSHostingView(rootView: previewView)
        hostingView.frame = NSRect(origin: .zero, size: previewSize)
        self.contentView = hostingView

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let origin = NSPoint(
                x: screenFrame.maxX - previewSize.width - 16,
                y: screenFrame.minY + 16
            )
            self.setFrameOrigin(origin)
        }
    }
}
