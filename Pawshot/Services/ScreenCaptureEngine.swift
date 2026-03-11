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

    func captureFullScreen(display: SCDisplay) async throws -> CGImage {
        guard PermissionService.shared.hasScreenCapturePermission else {
            throw CaptureError.noPermission
        }

        if #available(macOS 14.0, *) {
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()
            config.width = display.width * 2
            config.height = display.height * 2
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

    func captureArea(display: SCDisplay, rect: CGRect) async throws -> CGImage {
        guard PermissionService.shared.hasScreenCapturePermission else {
            throw CaptureError.noPermission
        }

        if #available(macOS 14.0, *) {
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()
            // Output size must match the source rect, scaled for Retina
            config.sourceRect = rect
            config.width = Int(rect.width) * 2
            config.height = Int(rect.height) * 2
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

    func captureWindow(_ window: SCWindow) async throws -> CGImage {
        guard PermissionService.shared.hasScreenCapturePermission else {
            throw CaptureError.noPermission
        }

        if #available(macOS 14.0, *) {
            let filter = SCContentFilter(desktopIndependentWindow: window)
            let config = SCStreamConfiguration()
            config.showsCursor = false
            config.width = Int(window.frame.width) * 2
            config.height = Int(window.frame.height) * 2

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
