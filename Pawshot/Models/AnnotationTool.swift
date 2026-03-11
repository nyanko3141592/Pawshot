import Foundation

enum AnnotationTool: String, CaseIterable, Identifiable {
    case arrow
    case line
    case rectangle
    case ellipse
    case text
    case highlighter
    case mosaic
    case crop

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .arrow: return "Arrow"
        case .line: return "Line"
        case .rectangle: return "Rectangle"
        case .ellipse: return "Ellipse"
        case .text: return "Text"
        case .highlighter: return "Highlighter"
        case .mosaic: return "Mosaic"
        case .crop: return "Crop"
        }
    }

    var systemImage: String {
        switch self {
        case .arrow: return "arrow.up.right"
        case .line: return "line.diagonal"
        case .rectangle: return "rectangle"
        case .ellipse: return "circle"
        case .text: return "textformat"
        case .highlighter: return "highlighter"
        case .mosaic: return "squareshape.split.3x3"
        case .crop: return "crop"
        }
    }
}
