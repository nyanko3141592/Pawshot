import Foundation

enum LaunchAgentService {
    private static let label = "com.pawshot.app"
    private static var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    static func install() {
        // Unload existing job first to avoid "already loaded" errors
        if FileManager.default.fileExists(atPath: plistURL.path) {
            let unload = Process()
            unload.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            unload.arguments = ["unload", plistURL.path]
            try? unload.run()
            unload.waitUntilExit()
        }

        let executablePath = Bundle.main.executablePath ?? (Bundle.main.bundlePath + "/Contents/MacOS/Pawshot")
        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [executablePath],
            "RunAtLoad": true,
            "KeepAlive": false,
        ]

        let dir = plistURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        guard let data = try? PropertyListSerialization.data(
            fromPropertyList: plist, format: .xml, options: 0
        ) else {
            print("LaunchAgent: Failed to serialize plist")
            return
        }

        do {
            try data.write(to: plistURL, options: .atomic)
        } catch {
            print("LaunchAgent: Failed to write plist: \(error)")
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["load", plistURL.path]
        try? process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            print("LaunchAgent: launchctl load failed with status \(process.terminationStatus)")
        }
    }

    static func uninstall() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["unload", plistURL.path]
        try? process.run()
        process.waitUntilExit()

        try? FileManager.default.removeItem(at: plistURL)
    }

    static func isInstalled() -> Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }
}
