import AppKit
import ScreenCaptureKit

final class PermissionService {
    static let shared = PermissionService()

    private init() {}

    var hasScreenCapturePermission: Bool {
        CGPreflightScreenCaptureAccess()
    }

    func requestScreenCapturePermission() {
        if !hasScreenCapturePermission {
            CGRequestScreenCaptureAccess()
        }
    }

    func checkAndPromptIfNeeded() async -> Bool {
        if hasScreenCapturePermission {
            return true
        }

        await MainActor.run {
            let alert = NSAlert()
            alert.messageText = "Screen Capture Permission Required"
            alert.informativeText = "Pawshot needs screen capture permission to take screenshots. Please enable it in System Settings > Privacy & Security > Screen Recording."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Cancel")

            if alert.runModal() == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                    NSWorkspace.shared.open(url)
                }
            }
        }

        return false
    }
}
