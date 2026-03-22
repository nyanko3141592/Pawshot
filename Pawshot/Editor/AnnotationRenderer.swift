import AppKit
import CoreImage

final class AnnotationRenderer {

    private static let ciContext = CIContext()

    // MARK: - Pixelated preview for blur/mosaic (canvas + final render)

    static func drawPixelatedPreview(annotation: Annotation, cgImage: CGImage, in context: CGContext, imagePointSize: NSSize) {
        let rawRect = annotation.boundingRect
        let clampedRect = rawRect.intersection(CGRect(origin: .zero, size: imagePointSize))
        guard clampedRect.width > 2, clampedRect.height > 2 else { return }

        let pixelSize: CGFloat = max(annotation.lineWidth * 5, 20)

        let scaleX = CGFloat(cgImage.width) / imagePointSize.width
        let scaleY = CGFloat(cgImage.height) / imagePointSize.height

        // CGImage.cropping uses top-left coordinates (matching pixel data layout)
        let cropRect = CGRect(
            x: clampedRect.origin.x * scaleX,
            y: clampedRect.origin.y * scaleY,
            width: clampedRect.width * scaleX,
            height: clampedRect.height * scaleY
        ).integral

        guard cropRect.width > 0, cropRect.height > 0 else { return }
        guard let croppedImage = cgImage.cropping(to: cropRect) else { return }

        let ciImage = CIImage(cgImage: croppedImage)
        let filter = CIFilter(name: "CIPixellate")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(pixelSize * max(scaleX, scaleY), forKey: kCIInputScaleKey)

        guard let output = filter.outputImage,
              let pixelatedImage = ciContext.createCGImage(output, from: ciImage.extent) else { return }

        // Use NSImage.draw with respectFlipped for correct orientation in flipped context
        let nsImage = NSImage(cgImage: pixelatedImage, size: clampedRect.size)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
        nsImage.draw(in: clampedRect, from: NSRect(origin: .zero, size: clampedRect.size),
                     operation: .sourceOver, fraction: 1.0, respectFlipped: true, hints: nil)
        NSGraphicsContext.restoreGraphicsState()

        // Draw subtle border
        context.saveGState()
        context.setStrokeColor(NSColor.systemGray.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(1.0)
        context.stroke(clampedRect)
        context.restoreGState()
    }

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
        case .mosaic:
            break // Handled by drawPixelatedPreview
        case .crop:
            drawCropOverlay(annotation, in: context, imageSize: imageSize)
        }

        context.restoreGState()
    }

    private static func drawArrow(_ annotation: Annotation, in context: CGContext) {
        let start = annotation.startPoint
        let end = annotation.endPoint

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

        // Stop the line at the base of the arrowhead so it doesn't poke through
        let lineEnd = CGPoint(
            x: (p1.x + p2.x) / 2,
            y: (p1.y + p2.y) / 2
        )

        context.move(to: start)
        context.addLine(to: lineEnd)
        context.strokePath()

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

    private static func drawCropOverlay(_ annotation: Annotation, in context: CGContext, imageSize: NSSize) {
        let rect = annotation.boundingRect

        // Use even-odd fill to darken only the area outside the crop rect
        context.saveGState()
        let path = CGMutablePath()
        path.addRect(CGRect(origin: .zero, size: imageSize))
        path.addRect(rect)
        context.setFillColor(NSColor.black.withAlphaComponent(0.5).cgColor)
        context.addPath(path)
        context.fillPath(using: .evenOdd)
        context.restoreGState()

        context.setStrokeColor(NSColor.white.cgColor)
        context.setLineWidth(2)
        context.stroke(rect)
    }

    // MARK: - Final Render

    static func renderFinalImage(screenshot: Screenshot, annotations: [Annotation]) -> CGImage? {
        guard let cgImage = screenshot.cgImage else { return nil }

        let pixelWidth = cgImage.width
        let pixelHeight = cgImage.height
        let pointSize = screenshot.image.size
        let pixelScaleX = CGFloat(pixelWidth) / pointSize.width
        let pixelScaleY = CGFloat(pixelHeight) / pointSize.height

        guard let context = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        // Draw original image (CGContext is bottom-left origin)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))

        // Apply mosaic annotations (works in pixel coordinates)
        for annotation in annotations where annotation.tool == .mosaic {
            applyPixellate(annotation: annotation, context: context, cgImage: cgImage,
                           pixelScaleX: pixelScaleX, pixelScaleY: pixelScaleY,
                           pixelSize: max(annotation.lineWidth * 5, 20))
        }

        // Flip and scale context: top-left point coords → bottom-left pixel coords
        context.saveGState()
        context.translateBy(x: 0, y: CGFloat(pixelHeight))
        context.scaleBy(x: pixelScaleX, y: -pixelScaleY)

        for annotation in annotations where annotation.tool != .mosaic && annotation.tool != .crop {
            draw(annotation: annotation, in: context, imageSize: pointSize)
        }
        context.restoreGState()

        // Handle crop — CGImage.cropping uses top-left coordinates
        if let cropAnnotation = annotations.last(where: { $0.tool == .crop }) {
            let cropRect = cropAnnotation.boundingRect
            // context.makeImage() produces a CGImage with top-left origin
            // Annotation coords are already top-left, just scale to pixels
            let pixelCropRect = CGRect(
                x: cropRect.origin.x * pixelScaleX,
                y: cropRect.origin.y * pixelScaleY,
                width: cropRect.width * pixelScaleX,
                height: cropRect.height * pixelScaleY
            )
            if let fullImage = context.makeImage() {
                return fullImage.cropping(to: pixelCropRect)
            }
        }

        return context.makeImage()
    }

    private static func applyPixellate(annotation: Annotation, context: CGContext, cgImage: CGImage,
                                        pixelScaleX: CGFloat, pixelScaleY: CGFloat, pixelSize: CGFloat) {
        let rect = annotation.boundingRect
        guard rect.width > 0, rect.height > 0 else { return }

        // Convert point coords to pixel coords
        let pixelRect = CGRect(
            x: rect.origin.x * pixelScaleX,
            y: rect.origin.y * pixelScaleY,
            width: rect.width * pixelScaleX,
            height: rect.height * pixelScaleY
        )

        // Flip to bottom-left origin for CGImage/CIImage
        let flippedRect = CGRect(
            x: pixelRect.origin.x,
            y: CGFloat(cgImage.height) - pixelRect.origin.y - pixelRect.height,
            width: pixelRect.width,
            height: pixelRect.height
        )

        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIPixellate")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(pixelSize * max(pixelScaleX, pixelScaleY), forKey: kCIInputScaleKey)
        filter.setValue(CIVector(x: flippedRect.midX, y: flippedRect.midY), forKey: kCIInputCenterKey)

        if let output = filter.outputImage,
           let blurredImage = ciContext.createCGImage(output, from: ciImage.extent) {
            context.saveGState()
            context.clip(to: flippedRect)
            context.draw(blurredImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
            context.restoreGState()
        }
    }
}
