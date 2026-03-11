import AppKit

final class SelectionOverlayWindow: NSWindow {
    init(screen: NSScreen, coordinator: CaptureCoordinator) {
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        self.level = .screenSaver
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isReleasedWhenClosed = false

        let overlayView = SelectionOverlayView(coordinator: coordinator, screen: screen)
        overlayView.frame = NSRect(origin: .zero, size: screen.frame.size)
        self.contentView = overlayView
    }
}
