import Foundation
import UniformTypeIdentifiers

enum ExportFormat: String, CaseIterable, Identifiable {
    case png
    case jpg
    case webp

    var id: String { rawValue }

    var displayName: String {
        rawValue.uppercased()
    }

    var fileExtension: String {
        rawValue
    }

    var utType: UTType {
        switch self {
        case .png: return .png
        case .jpg: return .jpeg
        case .webp: return .webP
        }
    }
}
