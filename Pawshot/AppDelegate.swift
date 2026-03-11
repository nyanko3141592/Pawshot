import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotkeyService: HotkeyService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        PermissionService.shared.requestScreenCapturePermission()

        hotkeyService = HotkeyService()
        hotkeyService?.registerDefaults()
    }
}
