import AppKit
import ScreenCaptureKit

final class ScreenCaptureEngine {
    enum CaptureError: LocalizedError {
        case noPermission
        case captureFailedSCK(String)
        case noDisplay
        case noImage

        var errorDescription: String? {
            switch self {
            case .noPermission: return "Screen capture permission not granted."
            case .captureFailedSCK(let msg): return "ScreenCaptureKit error: \(msg)"
            case .noDisplay: return "No display found."
            case .noImage: return "Failed to create image."
            }
        }
    }

    func captureFullScreen(display: SCDisplay, pixelScale: CGFloat) async throws -> CGImage {
        guard PermissionService.shared.hasScreenCapturePermission else {
            throw CaptureError.noPermission
        }

        if #available(macOS 14.0, *) {
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()
            config.width = Int(CGFloat(display.width) * pixelScale)
            config.height = Int(CGFloat(display.height) * pixelScale)
            config.showsCursor = false

            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )
            return image
        } else {
            let fallback = LegacyCaptureEngine()
            guard let image = fallback.captureFullScreen(displayID: display.displayID) else {
                throw CaptureError.noImage
            }
            return image
        }
    }

    func captureArea(display: SCDisplay, rect: CGRect, pixelScale: CGFloat) async throws -> CGImage {
        guard PermissionService.shared.hasScreenCapturePermission else {
            throw CaptureError.noPermission
        }

        if #available(macOS 14.0, *) {
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()
            // sourceRect is in points (relative to the filter's content);
            // width/height are output pixels. Keep the aspect ratio aligned
            // with the display's actual backing scale so no extra padding
            // is introduced around the captured area.
            config.sourceRect = rect
            config.width = Int((rect.width * pixelScale).rounded())
            config.height = Int((rect.height * pixelScale).rounded())
            config.showsCursor = false

            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )
            return image
        } else {
            let fallback = LegacyCaptureEngine()
            guard let image = fallback.captureArea(displayID: display.displayID, rect: rect) else {
                throw CaptureError.noImage
            }
            return image
        }
    }

    func captureWindow(_ window: SCWindow, pixelScale: CGFloat) async throws -> CGImage {
        guard PermissionService.shared.hasScreenCapturePermission else {
            throw CaptureError.noPermission
        }

        if #available(macOS 14.0, *) {
            let filter = SCContentFilter(desktopIndependentWindow: window)
            let config = SCStreamConfiguration()
            config.showsCursor = false
            config.width = Int((window.frame.width * pixelScale).rounded())
            config.height = Int((window.frame.height * pixelScale).rounded())

            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: config
            )
            return image
        } else {
            let fallback = LegacyCaptureEngine()
            guard let image = fallback.captureWindow(windowID: window.windowID) else {
                throw CaptureError.noImage
            }
            return image
        }
    }
}
