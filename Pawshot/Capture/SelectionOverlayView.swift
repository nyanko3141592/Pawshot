import AppKit

final class SelectionOverlayView: NSView {
    private let screenFrame: NSRect
    private let screenOrigin: NSPoint

    private var selectionStart: NSPoint?
    private var selectionEnd: NSPoint?
    private var currentMousePosition: NSPoint = .zero

    private var selectionRect: NSRect? {
        guard let start = selectionStart, let end = selectionEnd else { return nil }
        return NSRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }

    init(coordinator: CaptureCoordinator, screen: NSScreen) {
        self.screenFrame = screen.frame
        self.screenOrigin = screen.frame.origin
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.black.withAlphaComponent(0.3).setFill()
        dirtyRect.fill()

        if let rect = selectionRect, rect.width > 1, rect.height > 1 {
            NSColor.clear.setFill()
            rect.fill(using: .copy)

            NSColor.white.setStroke()
            let borderPath = NSBezierPath(rect: rect)
            borderPath.lineWidth = 1.0
            borderPath.stroke()

            drawDimensionLabel(for: rect)
        }

        drawCrosshair()
    }

    private func drawCrosshair() {
        guard selectionStart == nil else { return }

        let pos = currentMousePosition
        NSColor.white.withAlphaComponent(0.5).setStroke()

        let hLine = NSBezierPath()
        hLine.move(to: NSPoint(x: 0, y: pos.y))
        hLine.line(to: NSPoint(x: bounds.width, y: pos.y))
        hLine.lineWidth = 0.5
        hLine.setLineDash([4, 4], count: 2, phase: 0)
        hLine.stroke()

        let vLine = NSBezierPath()
        vLine.move(to: NSPoint(x: pos.x, y: 0))
        vLine.line(to: NSPoint(x: pos.x, y: bounds.height))
        vLine.lineWidth = 0.5
        vLine.setLineDash([4, 4], count: 2, phase: 0)
        vLine.stroke()
    }

    private func drawDimensionLabel(for rect: NSRect) {
        let text = "\(Int(rect.width)) × \(Int(rect.height))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white,
        ]
        let size = (text as NSString).size(withAttributes: attributes)
        let labelRect = NSRect(
            x: rect.midX - size.width / 2 - 6,
            y: rect.minY - size.height - 8,
            width: size.width + 12,
            height: size.height + 4
        )

        NSColor.black.withAlphaComponent(0.7).setFill()
        let bgPath = NSBezierPath(roundedRect: labelRect, xRadius: 4, yRadius: 4)
        bgPath.fill()

        let textPoint = NSPoint(x: labelRect.origin.x + 6, y: labelRect.origin.y + 2)
        (text as NSString).draw(at: textPoint, withAttributes: attributes)
    }

    override func mouseMoved(with event: NSEvent) {
        currentMousePosition = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        selectionStart = convert(event.locationInWindow, from: nil)
        selectionEnd = selectionStart
    }

    override func mouseDragged(with event: NSEvent) {
        selectionEnd = convert(event.locationInWindow, from: nil)
        currentMousePosition = selectionEnd!
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        selectionEnd = convert(event.locationInWindow, from: nil)

        guard let rect = selectionRect, rect.width > 5, rect.height > 5 else {
            // Click without drag = cancel
            CaptureCoordinator.shared.cancelCapture()
            return
        }

        let screenRect = NSRect(
            x: rect.origin.x + screenOrigin.x,
            y: rect.origin.y + screenOrigin.y,
            width: rect.width,
            height: rect.height
        )

        // Find the matching screen at the time of capture
        let matchingScreen = NSScreen.screens.first { $0.frame.origin == screenOrigin }
        CaptureCoordinator.shared.completeAreaCapture(rect: screenRect, screen: matchingScreen ?? NSScreen.main!)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            CaptureCoordinator.shared.cancelCapture()
        }
    }
}
