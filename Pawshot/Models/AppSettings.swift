import SwiftUI

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @AppStorage("exportFormat") var exportFormat: String = ExportFormat.png.rawValue
    @AppStorage("jpegQuality") var jpegQuality: Double = 0.85
    @AppStorage("savePath") var savePath: String = NSHomeDirectory() + "/Desktop"
    @AppStorage("copyToClipboard") var copyToClipboard: Bool = true
    @AppStorage("saveToFile") var saveToFile: Bool = false
    @AppStorage("showFloatingPreview") var showFloatingPreview: Bool = true
    @AppStorage("floatingPreviewDuration") var floatingPreviewDuration: Double = 10.0
    @AppStorage("captureWindowShadow") var captureWindowShadow: Bool = true
    @AppStorage("playCaptureSound") var playCaptureSound: Bool = true
    @AppStorage("hasShownShortcutGuide") var hasShownShortcutGuide: Bool = false

    var selectedExportFormat: ExportFormat {
        get { ExportFormat(rawValue: exportFormat) ?? .png }
        set { exportFormat = newValue.rawValue }
    }

    private init() {}
}
