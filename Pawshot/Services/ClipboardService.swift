import AppKit

final class ClipboardService {
    static let shared = ClipboardService()

    private init() {}

    func copyToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    func copyToClipboard(_ cgImage: CGImage) {
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        copyToClipboard(nsImage)
    }
}
