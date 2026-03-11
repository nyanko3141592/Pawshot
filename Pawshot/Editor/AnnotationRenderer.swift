import AppKit
import CoreImage

final class AnnotationRenderer {

    // MARK: - Canvas preview drawing (flipped coordinate system)

    static func draw(annotation: Annotation, in context: CGContext, imageSize: NSSize) {
        context.saveGState()
        context.setStrokeColor(annotation.color.cgColor)
        context.setFillColor(annotation.color.cgColor)
        context.setLineWidth(annotation.lineWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        switch annotation.tool {
        case .arrow:
            drawArrow(annotation, in: context)
        case .line:
            drawLine(annotation, in: context)
        case .rectangle:
            drawRectangle(annotation, in: context)
        case .ellipse:
            drawEllipse(annotation, in: context)
        case .text:
            drawText(annotation, in: context)
        case .highlighter:
            drawHighlighter(annotation, in: context)
        case .blur, .mosaic:
            drawBlurPreview(annotation, in: context)
        case .crop:
            drawCropOverlay(annotation, in: context, imageSize: imageSize)
        }

        context.restoreGState()
    }

    private static func drawArrow(_ annotation: Annotation, in context: CGContext) {
        let start = annotation.startPoint
        let end = annotation.endPoint

        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()

        let angle = atan2(end.y - start.y, end.x - start.x)
        let arrowLength: CGFloat = max(annotation.lineWidth * 5, 15)
        let arrowAngle: CGFloat = .pi / 6

        let p1 = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        let p2 = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )

        context.move(to: end)
        context.addLine(to: p1)
        context.addLine(to: p2)
        context.closePath()
        context.fillPath()
    }

    private static func drawLine(_ annotation: Annotation, in context: CGContext) {
        context.move(to: annotation.startPoint)
        context.addLine(to: annotation.endPoint)
        context.strokePath()
    }

    private static func drawRectangle(_ annotation: Annotation, in context: CGContext) {
        context.stroke(annotation.boundingRect)
    }

    private static func drawEllipse(_ annotation: Annotation, in context: CGContext) {
        context.strokeEllipse(in: annotation.boundingRect)
    }

    private static func drawText(_ annotation: Annotation, in context: CGContext) {
        guard let text = annotation.text, !text.isEmpty else { return }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: annotation.fontSize, weight: .medium),
            .foregroundColor: annotation.color,
        ]

        let nsString = text as NSString

        // Draw in flipped coordinate system (matching isFlipped = true canvas)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
        nsString.draw(at: annotation.startPoint, withAttributes: attributes)
        NSGraphicsContext.restoreGraphicsState()
    }

    private static func drawHighlighter(_ annotation: Annotation, in context: CGContext) {
        guard annotation.points.count > 1 else { return }

        context.setAlpha(0.3)
        context.setLineWidth(annotation.lineWidth * 5)

        context.move(to: annotation.points[0])
        for i in 1..<annotation.points.count {
            context.addLine(to: annotation.points[i])
        }
        context.strokePath()
    }

    private static func drawBlurPreview(_ annotation: Annotation, in context: CGContext) {
        // Show a hatched rectangle as preview for blur/mosaic area
        let rect = annotation.boundingRect
        guard rect.width > 0, rect.height > 0 else { return }

        context.setStrokeColor(NSColor.systemGray.withAlphaComponent(0.8).cgColor)
        context.setLineWidth(1.5)
        context.stroke(rect)

        // Draw crosshatch pattern inside
        context.saveGState()
        context.clip(to: rect)
        context.setStrokeColor(NSColor.systemGray.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(0.5)
        let spacing: CGFloat = 8
        var x = rect.minX
        while x < rect.maxX + rect.height {
            context.move(to: CGPoint(x: x, y: rect.minY))
            context.addLine(to: CGPoint(x: x - rect.height, y: rect.maxY))
            x += spacing
        }
        context.strokePath()
        context.restoreGState()
    }

    private static func drawCropOverlay(_ annotation: Annotation, in context: CGContext, imageSize: NSSize) {
        let rect = annotation.boundingRect

        context.saveGState()
        context.setFillColor(NSColor.black.withAlphaComponent(0.5).cgColor)
        context.fill(CGRect(origin: .zero, size: imageSize))
        context.clear(rect)
        context.restoreGState()

        context.setStrokeColor(NSColor.white.cgColor)
        context.setLineWidth(2)
        context.stroke(rect)
    }

    // MARK: - Final Render

    static func renderFinalImage(screenshot: Screenshot, annotations: [Annotation]) -> CGImage? {
        guard let cgImage = screenshot.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let imageSize = NSSize(width: width, height: height)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        // Draw original image (CGContext is bottom-left origin)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Apply blur/mosaic annotations
        for annotation in annotations where annotation.tool == .blur {
            applyPixellate(annotation: annotation, context: context, cgImage: cgImage, pixelSize: max(annotation.lineWidth * 3, 10))
        }
        for annotation in annotations where annotation.tool == .mosaic {
            applyPixellate(annotation: annotation, context: context, cgImage: cgImage, pixelSize: max(annotation.lineWidth * 5, 20))
        }

        // Flip context to match annotation coordinates (top-left origin)
        context.saveGState()
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)

        for annotation in annotations where annotation.tool != .blur && annotation.tool != .mosaic && annotation.tool != .crop {
            draw(annotation: annotation, in: context, imageSize: imageSize)
        }
        context.restoreGState()

        // Handle crop
        if let cropAnnotation = annotations.last(where: { $0.tool == .crop }) {
            let cropRect = cropAnnotation.boundingRect
            let flippedRect = CGRect(
                x: cropRect.origin.x,
                y: CGFloat(height) - cropRect.origin.y - cropRect.height,
                width: cropRect.width,
                height: cropRect.height
            )
            if let fullImage = context.makeImage() {
                return fullImage.cropping(to: flippedRect)
            }
        }

        return context.makeImage()
    }

    private static func applyPixellate(annotation: Annotation, context: CGContext, cgImage: CGImage, pixelSize: CGFloat) {
        let rect = annotation.boundingRect
        guard rect.width > 0, rect.height > 0 else { return }

        // Convert from top-left to bottom-left coordinates
        let flippedRect = CGRect(
            x: rect.origin.x,
            y: CGFloat(cgImage.height) - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )

        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIPixellate")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(pixelSize, forKey: kCIInputScaleKey)
        filter.setValue(CIVector(x: flippedRect.midX, y: flippedRect.midY), forKey: kCIInputCenterKey)

        let ciContext = CIContext()
        if let output = filter.outputImage,
           let blurredImage = ciContext.createCGImage(output, from: ciImage.extent) {
            context.saveGState()
            context.clip(to: flippedRect)
            context.draw(blurredImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
            context.restoreGState()
        }
    }
}
