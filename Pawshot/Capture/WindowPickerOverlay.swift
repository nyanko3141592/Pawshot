import AppKit
import ScreenCaptureKit

final class WindowPickerOverlay {
    private var overlayWindows: [WindowPickerOverlayWindow] = []
    private var discoveredWindows: [DiscoveredWindow] = []
    private var highlightWindow: NSWindow?

    func show() {
        Task { @MainActor in
            do {
                discoveredWindows = try await WindowDiscoveryService.shared.discoverWindows()
            } catch {
                print("Window discovery failed: \(error)")
                CaptureCoordinator.shared.cancelCapture()
                return
            }

            for screen in NSScreen.screens {
                let window = WindowPickerOverlayWindow(
                    screen: screen,
                    discoveredWindows: discoveredWindows,
                    picker: self
                )
                window.makeKeyAndOrderFront(nil)
                overlayWindows.append(window)
            }
        }
    }

    func dismiss() {
        let windows = overlayWindows
        overlayWindows.removeAll()
        windows.forEach { $0.orderOut(nil) }

        highlightWindow?.orderOut(nil)
        highlightWindow = nil
    }

    @MainActor
    func selectWindow(_ window: DiscoveredWindow) {
        CaptureCoordinator.shared.completeWindowCapture(window: window.scWindow)
    }

    @MainActor
    func cancel() {
        CaptureCoordinator.shared.cancelCapture()
    }

    @MainActor
    func highlightWindowFrame(_ frame: CGRect?) {
        if let frame = frame {
            if highlightWindow == nil {
                let hw = NSWindow(
                    contentRect: .zero,
                    styleMask: .borderless,
                    backing: .buffered,
                    defer: false
                )
                hw.level = .screenSaver + 1
                hw.isOpaque = false
                hw.backgroundColor = .clear
                hw.hasShadow = false
                hw.ignoresMouseEvents = true
                hw.isReleasedWhenClosed = false
                highlightWindow = hw
            }

            let primaryScreen = NSScreen.screens.first!
            let nsFrame = NSRect(
                x: frame.origin.x,
                y: primaryScreen.frame.height - frame.origin.y - frame.height,
                width: frame.width,
                height: frame.height
            )

            highlightWindow?.setFrame(nsFrame, display: true)

            let highlightView = WindowHighlightView(frame: NSRect(origin: .zero, size: nsFrame.size))
            highlightWindow?.contentView = highlightView
            highlightWindow?.orderFront(nil)
        } else {
            highlightWindow?.orderOut(nil)
        }
    }
}

private class WindowHighlightView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor.systemBlue.withAlphaComponent(0.2).setFill()
        bounds.fill()

        NSColor.systemBlue.withAlphaComponent(0.8).setStroke()
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 8, yRadius: 8)
        path.lineWidth = 3
        path.stroke()
    }
}

final class WindowPickerOverlayWindow: NSWindow {
    init(screen: NSScreen, discoveredWindows: [DiscoveredWindow], picker: WindowPickerOverlay) {
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

        let view = WindowPickerView(
            discoveredWindows: discoveredWindows,
            picker: picker
        )
        view.frame = NSRect(origin: .zero, size: screen.frame.size)
        self.contentView = view
    }
}

private final class WindowPickerView: NSView {
    private let discoveredWindows: [DiscoveredWindow]
    private weak var picker: WindowPickerOverlay?
    private var hoveredWindow: DiscoveredWindow?

    init(discoveredWindows: [DiscoveredWindow], picker: WindowPickerOverlay) {
        self.discoveredWindows = discoveredWindows
        self.picker = picker
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.3).setFill()
        dirtyRect.fill()

        let text = "Click a window to capture it. Press Escape to cancel."
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18, weight: .medium),
            .foregroundColor: NSColor.white,
        ]
        let size = (text as NSString).size(withAttributes: attributes)
        let point = NSPoint(x: bounds.midX - size.width / 2, y: bounds.height - 60)
        (text as NSString).draw(at: point, withAttributes: attributes)
    }

    override func mouseMoved(with event: NSEvent) {
        let screenPoint = NSEvent.mouseLocation

        let primaryScreen = NSScreen.screens.first!
        let cgPoint = CGPoint(
            x: screenPoint.x,
            y: primaryScreen.frame.height - screenPoint.y
        )

        let matched = discoveredWindows.first { window in
            window.frame.contains(cgPoint)
        }

        if matched?.id != hoveredWindow?.id {
            hoveredWindow = matched
            picker?.highlightWindowFrame(matched?.frame)
        }
    }

    override func mouseDown(with event: NSEvent) {
        if let window = hoveredWindow {
            picker?.selectWindow(window)
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            picker?.cancel()
        }
    }
}
