import Foundation

enum CaptureMode: String, CaseIterable, Identifiable {
    case area
    case window
    case fullScreen

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .area: return "Capture Area"
        case .window: return "Capture Window"
        case .fullScreen: return "Capture Full Screen"
        }
    }

    var systemImage: String {
        switch self {
        case .area: return "rectangle.dashed"
        case .window: return "macwindow"
        case .fullScreen: return "rectangle.inset.filled"
        }
    }
}
