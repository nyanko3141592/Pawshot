import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotkeyService: HotkeyService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        PermissionService.shared.requestScreenCapturePermission()

        hotkeyService = HotkeyService()
        hotkeyService?.registerDefaults()

        showShortcutGuideIfNeeded()
    }

    private func showShortcutGuideIfNeeded() {
        let settings = AppSettings.shared
        guard !settings.hasShownShortcutGuide else { return }
        settings.hasShownShortcutGuide = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let alert = NSAlert()
            alert.messageText = "Disable macOS Screenshot Shortcuts"
            alert.informativeText = """
            Pawshot uses ⌘⇧3, ⌘⇧4, and ⌘⇧5 for capture, which conflict with macOS built-in screenshot shortcuts.

            To use Pawshot's hotkeys, please disable the system shortcuts:

            System Settings → Keyboard → Keyboard Shortcuts → Screenshots

            Uncheck the conflicting shortcuts.
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Later")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension?Shortcuts") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
