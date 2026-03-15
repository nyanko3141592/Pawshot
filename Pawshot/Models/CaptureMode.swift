import Foundation

enum CaptureMode: String, CaseIterable, Identifiable {
    case area
    case window
    case fullScreen
    case ocrText

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .area: return "Capture Area"
        case .window: return "Capture Window"
        case .fullScreen: return "Capture Full Screen"
        case .ocrText: return "OCR Text"
        }
    }

    var systemImage: String {
        switch self {
        case .area: return "rectangle.dashed"
        case .window: return "macwindow"
        case .fullScreen: return "rectangle.inset.filled"
        case .ocrText: return "text.viewfinder"
        }
    }

    /// Standard capture modes (excluding OCR)
    static var captureModes: [CaptureMode] {
        [.fullScreen, .area, .window]
    }
}
