import AppKit
import ScreenCaptureKit

final class CaptureService {
    private let engine = ScreenCaptureEngine()

    private func nsImage(from cgImage: CGImage, pixelScale: CGFloat) -> NSImage {
        // NSImage size is in points. CGImage dimensions are pixels.
        let scale = pixelScale > 0 ? pixelScale : 2.0
        let pointSize = NSSize(
            width: CGFloat(cgImage.width) / scale,
            height: CGFloat(cgImage.height) / scale
        )
        return NSImage(cgImage: cgImage, size: pointSize)
    }

    private func scaleFactor(for displayID: CGDirectDisplayID) -> CGFloat {
        NSScreen.screens.first { $0.displayID == displayID }?.backingScaleFactor
            ?? NSScreen.main?.backingScaleFactor
            ?? 2.0
    }

    func captureFullScreen() async throws -> Screenshot {
        let displays = try await WindowDiscoveryService.shared.displays()
        guard let mainDisplay = displays.first else {
            throw ScreenCaptureEngine.CaptureError.noDisplay
        }

        let scale = scaleFactor(for: mainDisplay.displayID)
        let cgImage = try await engine.captureFullScreen(display: mainDisplay, pixelScale: scale)
        return Screenshot(image: nsImage(from: cgImage, pixelScale: scale), captureMode: .fullScreen)
    }

    func captureArea(display: SCDisplay, rect: CGRect, pixelScale: CGFloat) async throws -> Screenshot {
        let cgImage = try await engine.captureArea(display: display, rect: rect, pixelScale: pixelScale)
        return Screenshot(image: nsImage(from: cgImage, pixelScale: pixelScale), captureMode: .area, rect: rect)
    }

    func captureWindow(_ window: SCWindow) async throws -> Screenshot {
        let scale = NSScreen.screens.first { screen in
            screen.frame.intersects(window.frame)
        }?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2.0
        let cgImage = try await engine.captureWindow(window, pixelScale: scale)
        return Screenshot(image: nsImage(from: cgImage, pixelScale: scale), captureMode: .window)
    }
}
