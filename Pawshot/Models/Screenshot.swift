import AppKit
import Foundation

struct Screenshot: Identifiable {
    let id: UUID
    let image: NSImage
    let capturedAt: Date
    let captureMode: CaptureMode
    let rect: CGRect?

    init(image: NSImage, captureMode: CaptureMode, rect: CGRect? = nil) {
        self.id = UUID()
        self.image = image
        self.capturedAt = Date()
        self.captureMode = captureMode
        self.rect = rect
    }

    var cgImage: CGImage? {
        image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
}
