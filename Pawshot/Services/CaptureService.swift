import AppKit
import ScreenCaptureKit

final class CaptureService {
    private let engine = ScreenCaptureEngine()

    private func nsImage(from cgImage: CGImage) -> NSImage {
        // NSImage size should be in points, not pixels
        // CGImage dimensions are pixels; divide by scale factor for points
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let pointSize = NSSize(
            width: CGFloat(cgImage.width) / scale,
            height: CGFloat(cgImage.height) / scale
        )
        return NSImage(cgImage: cgImage, size: pointSize)
    }

    func captureFullScreen() async throws -> Screenshot {
        let displays = try await WindowDiscoveryService.shared.displays()
        guard let mainDisplay = displays.first else {
            throw ScreenCaptureEngine.CaptureError.noDisplay
        }

        let cgImage = try await engine.captureFullScreen(display: mainDisplay)
        return Screenshot(image: nsImage(from: cgImage), captureMode: .fullScreen)
    }

    func captureArea(display: SCDisplay, rect: CGRect) async throws -> Screenshot {
        let cgImage = try await engine.captureArea(display: display, rect: rect)
        return Screenshot(image: nsImage(from: cgImage), captureMode: .area, rect: rect)
    }

    func captureWindow(_ window: SCWindow) async throws -> Screenshot {
        let cgImage = try await engine.captureWindow(window)
        return Screenshot(image: nsImage(from: cgImage), captureMode: .window)
    }
}
