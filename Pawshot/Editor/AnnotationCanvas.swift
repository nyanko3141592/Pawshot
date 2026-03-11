import AppKit
import SwiftUI

struct AnnotationCanvas: NSViewRepresentable {
    @ObservedObject var state: EditorState

    func makeNSView(context: Context) -> AnnotationCanvasView {
        let view = AnnotationCanvasView(state: state)
        view.autoresizingMask = [.width, .height]
        return view
    }

    func updateNSView(_ nsView: AnnotationCanvasView, context: Context) {
        nsView.state = state
        nsView.needsDisplay = true
    }
}

final class AnnotationCanvasView: NSView {
    var state: EditorState

    init(state: EditorState) {
        self.state = state
        super.init(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { true }

    override var intrinsicContentSize: NSSize {
        let imageSize = state.screenshot.image.size
        guard imageSize.width > 0, imageSize.height > 0 else {
            return NSSize(width: 400, height: 300)
        }
        return imageSize
    }

    private var imageRect: NSRect {
        let imageSize = state.screenshot.image.size
        let viewSize = bounds.size
        guard viewSize.width > 0, viewSize.height > 0,
              imageSize.width > 0, imageSize.height > 0 else {
            return .zero
        }
        let scale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale
        return NSRect(
            x: floor((viewSize.width - scaledWidth) / 2),
            y: floor((viewSize.height - scaledHeight) / 2),
            width: ceil(scaledWidth),
            height: ceil(scaledHeight)
        )
    }

    private func viewPointToImagePoint(_ point: NSPoint) -> NSPoint {
        let rect = imageRect
        guard rect.width > 0, rect.height > 0 else { return .zero }
        let imageSize = state.screenshot.image.size
        return NSPoint(
            x: (point.x - rect.origin.x) / rect.width * imageSize.width,
            y: (point.y - rect.origin.y) / rect.height * imageSize.height
        )
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Background
        context.setFillColor(NSColor.controlBackgroundColor.cgColor)
        context.fill(bounds)

        let rect = imageRect
        guard rect.width > 0, rect.height > 0 else { return }

        // Draw screenshot - use NSImage.draw which handles flipped views correctly
        state.screenshot.image.draw(
            in: rect,
            from: NSRect(origin: .zero, size: state.screenshot.image.size),
            operation: .sourceOver,
            fraction: 1.0,
            respectFlipped: true,
            hints: [.interpolation: NSImageInterpolation.high]
        )

        // Draw annotations
        let imageSize = state.screenshot.image.size
        let scale = rect.width / imageSize.width

        context.saveGState()
        context.translateBy(x: rect.origin.x, y: rect.origin.y)
        context.scaleBy(x: scale, y: scale)

        // Draw pixelated regions for blur/mosaic annotations
        if let cgImage = state.screenshot.cgImage {
            for annotation in state.annotations where annotation.tool == .mosaic {
                AnnotationRenderer.drawPixelatedPreview(annotation: annotation, cgImage: cgImage, in: context, imagePointSize: imageSize)
            }
            if let current = state.currentAnnotation, current.tool == .mosaic {
                AnnotationRenderer.drawPixelatedPreview(annotation: current, cgImage: cgImage, in: context, imagePointSize: imageSize)
            }
        }

        // Draw non-mosaic annotations
        for annotation in state.annotations where annotation.tool != .mosaic {
            AnnotationRenderer.draw(annotation: annotation, in: context, imageSize: imageSize)
        }

        if let current = state.currentAnnotation, current.tool != .mosaic {
            AnnotationRenderer.draw(annotation: current, in: context, imageSize: imageSize)
        }

        context.restoreGState()
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let imagePoint = viewPointToImagePoint(point)
        state.beginAnnotation(at: imagePoint)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let imagePoint = viewPointToImagePoint(point)
        state.continueAnnotation(at: imagePoint)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let imagePoint = viewPointToImagePoint(point)
        state.endAnnotation(at: imagePoint)
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "z" {
            if event.modifierFlags.contains(.shift) {
                state.redo()
            } else {
                state.undo()
            }
            needsDisplay = true
        }
    }
}
