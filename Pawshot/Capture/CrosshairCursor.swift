import AppKit

enum CrosshairCursor {
    static func create() -> NSCursor {
        let size = NSSize(width: 32, height: 32)
        let image = NSImage(size: size, flipped: false) { rect in
            let center = NSPoint(x: rect.midX, y: rect.midY)

            NSColor.white.setStroke()
            let hLine = NSBezierPath()
            hLine.move(to: NSPoint(x: 0, y: center.y))
            hLine.line(to: NSPoint(x: rect.width, y: center.y))
            hLine.lineWidth = 1.5
            hLine.stroke()

            let vLine = NSBezierPath()
            vLine.move(to: NSPoint(x: center.x, y: 0))
            vLine.line(to: NSPoint(x: center.x, y: rect.height))
            vLine.lineWidth = 1.5
            vLine.stroke()

            NSColor.black.setStroke()
            let hLineInner = NSBezierPath()
            hLineInner.move(to: NSPoint(x: 0, y: center.y))
            hLineInner.line(to: NSPoint(x: rect.width, y: center.y))
            hLineInner.lineWidth = 0.5
            hLineInner.stroke()

            let vLineInner = NSBezierPath()
            vLineInner.move(to: NSPoint(x: center.x, y: 0))
            vLineInner.line(to: NSPoint(x: center.x, y: rect.height))
            vLineInner.lineWidth = 0.5
            vLineInner.stroke()

            return true
        }

        return NSCursor(image: image, hotSpot: NSPoint(x: 16, y: 16))
    }
}
