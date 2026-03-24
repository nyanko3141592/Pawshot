import Foundation

enum LaunchAgentService {
    private static let label = "com.pawshot.app"
    private static var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    static func install() {
        let executablePath = Bundle.main.bundlePath + "/Contents/MacOS/Pawshot"
        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [executablePath],
            "RunAtLoad": true,
            "KeepAlive": false,
        ]

        let dir = plistURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let data = try? PropertyListSerialization.data(
            fromPropertyList: plist, format: .xml, options: 0
        )
        try? data?.write(to: plistURL, options: .atomic)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["load", plistURL.path]
        try? process.run()
        process.waitUntilExit()
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
