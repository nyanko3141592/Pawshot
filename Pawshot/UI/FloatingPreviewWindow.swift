import AppKit
import SwiftUI

final class FloatingPreviewWindow: NSPanel {
    let previewID: UUID

    init(screenshot: Screenshot, coordinator: CaptureCoordinator, previewID: UUID) {
        self.previewID = previewID

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
        self.isMovableByWindowBackground = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.animationBehavior = .utilityWindow
        self.isReleasedWhenClosed = false

        let previewView = FloatingPreviewView(
            screenshot: screenshot,
            coordinator: coordinator,
            previewSize: previewSize,
            previewID: previewID
        )
        let hostingView = NSHostingView(rootView: previewView)
        hostingView.frame = NSRect(origin: .zero, size: previewSize)

        // Wrap in a draggable container for reliable drag & drop from non-activating panel
        let dragContainer = DraggablePreviewContainerView(
            hostingView: hostingView,
            screenshot: screenshot,
            frame: NSRect(origin: .zero, size: previewSize)
        )
        self.contentView = dragContainer
    }
}

/// AppKit container that provides native drag & drop support.
/// SwiftUI's `.onDrag` doesn't work reliably in non-activating NSPanel windows,
/// so we intercept mouseDragged here and start a proper NSDraggingSession.
final class DraggablePreviewContainerView: NSView, NSDraggingSource {
    private let screenshot: Screenshot
    private var dragThresholdExceeded = false
    private var mouseDownLocation: NSPoint = .zero

    init(hostingView: NSView, screenshot: Screenshot, frame: NSRect) {
        self.screenshot = screenshot
        super.init(frame: frame)
        hostingView.frame = bounds
        hostingView.autoresizingMask = [.width, .height]
        addSubview(hostingView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        return context == .outsideApplication ? .copy : []
    }

    override func mouseDown(with event: NSEvent) {
        mouseDownLocation = event.locationInWindow
        dragThresholdExceeded = false
        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        let current = event.locationInWindow
        let dx = current.x - mouseDownLocation.x
        let dy = current.y - mouseDownLocation.y
        let distance = sqrt(dx * dx + dy * dy)

        // Only start drag after a 4pt threshold to avoid interfering with clicks
        guard distance > 4, !dragThresholdExceeded else {
            super.mouseDragged(with: event)
            return
        }
        dragThresholdExceeded = true

        let timestamp = ISO8601DateFormatter().string(from: screenshot.capturedAt)
            .replacingOccurrences(of: ":", with: "-")
        let filename = "Pawshot_\(timestamp).png"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        guard let tiff = screenshot.image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]),
              let _ = try? png.write(to: tempURL) else {
            return
        }

        let draggingItem = NSDraggingItem(pasteboardWriter: tempURL as NSURL)
        let dragImage = screenshot.image.resized(to: bounds.size)
        draggingItem.setDraggingFrame(bounds, contents: dragImage)

        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }
}
