import AppKit
import UniformTypeIdentifiers

final class FileExportService {
    static let shared = FileExportService()

    private init() {}

    func save(_ image: NSImage, format: ExportFormat = .png, to directory: String? = nil) throws -> URL {
        let settings = AppSettings.shared
        let saveDir = directory ?? settings.savePath
        let timestamp = DateFormatter.screenshotFormatter.string(from: Date())
        let filename = "Pawshot \(timestamp).\(format.fileExtension)"
        let url = URL(fileURLWithPath: saveDir).appendingPathComponent(filename)

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            throw ExportError.conversionFailed
        }

        let data: Data?
        switch format {
        case .png:
            data = bitmap.representation(using: .png, properties: [:])
        case .jpg:
            data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: settings.jpegQuality])
        case .webp:
            data = bitmap.representation(using: .png, properties: [:])
        }

        guard let imageData = data else {
            throw ExportError.encodingFailed
        }

        try imageData.write(to: url)
        return url
    }

    func saveWithPanel(_ image: NSImage, format: ExportFormat = .png) async throws -> URL? {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let panel = NSSavePanel()
                panel.allowedContentTypes = [format.utType]
                panel.nameFieldStringValue = "Pawshot \(DateFormatter.screenshotFormatter.string(from: Date())).\(format.fileExtension)"
                panel.canCreateDirectories = true

                panel.begin { response in
                    guard response == .OK, let url = panel.url else {
                        continuation.resume(returning: nil)
                        return
                    }

                    do {
                        guard let tiffData = image.tiffRepresentation,
                              let bitmap = NSBitmapImageRep(data: tiffData) else {
                            continuation.resume(throwing: ExportError.conversionFailed)
                            return
                        }

                        let data: Data?
                        switch format {
                        case .png:
                            data = bitmap.representation(using: .png, properties: [:])
                        case .jpg:
                            data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: AppSettings.shared.jpegQuality])
                        case .webp:
                            data = bitmap.representation(using: .png, properties: [:])
                        }

                        guard let imageData = data else {
                            continuation.resume(throwing: ExportError.encodingFailed)
                            return
                        }

                        try imageData.write(to: url)
                        continuation.resume(returning: url)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    enum ExportError: LocalizedError {
        case conversionFailed
        case encodingFailed

        var errorDescription: String? {
            switch self {
            case .conversionFailed: return "Failed to convert image."
            case .encodingFailed: return "Failed to encode image."
            }
        }
    }
}

extension DateFormatter {
    static let screenshotFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return f
    }()
}
