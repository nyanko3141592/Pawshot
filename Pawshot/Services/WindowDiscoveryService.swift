import AppKit
import ScreenCaptureKit

struct DiscoveredWindow: Identifiable {
    let id: CGWindowID
    let scWindow: SCWindow
    let title: String
    let appName: String
    let frame: CGRect
    let isOnScreen: Bool

    init(scWindow: SCWindow) {
        self.id = scWindow.windowID
        self.scWindow = scWindow
        self.title = scWindow.title ?? ""
        self.appName = scWindow.owningApplication?.applicationName ?? ""
        self.frame = scWindow.frame
        self.isOnScreen = scWindow.isOnScreen
    }
}

final class WindowDiscoveryService {
    static let shared = WindowDiscoveryService()

    private init() {}

    func discoverWindows() async throws -> [DiscoveredWindow] {
        let content = try await SCShareableContent.excludingDesktopWindows(
            true,
            onScreenWindowsOnly: true
        )

        return content.windows
            .filter { window in
                guard let app = window.owningApplication else { return false }
                return app.bundleIdentifier != Bundle.main.bundleIdentifier
                    && window.frame.width > 50
                    && window.frame.height > 50
                    && window.isOnScreen
            }
            .map { DiscoveredWindow(scWindow: $0) }
    }

    func displays() async throws -> [SCDisplay] {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        return content.displays
    }
}
