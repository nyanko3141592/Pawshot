import SwiftUI
import UniformTypeIdentifiers

struct FloatingPreviewView: View {
    let screenshot: Screenshot
    let coordinator: CaptureCoordinator
    let previewSize: NSSize

    @State private var isHovering = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Use resized image to avoid layout mismatch
            Image(nsImage: screenshot.image.resized(to: previewSize))
                .frame(width: previewSize.width, height: previewSize.height)
                .clipped()
                .onDrag {
                    provideImageForDrag()
                }

            if isHovering {
                buttonOverlay
            }
        }
        .frame(width: previewSize.width, height: previewSize.height)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 8)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
            if hovering {
                FloatingPreviewService.shared.pauseTimer()
            } else {
                FloatingPreviewService.shared.resumeTimer()
            }
        }
    }

    private func provideImageForDrag() -> NSItemProvider {
        let provider = NSItemProvider()

        // Pause auto-dismiss while dragging
        FloatingPreviewService.shared.pauseTimer()

        provider.registerFileRepresentation(
            forTypeIdentifier: UTType.png.identifier,
            visibility: .all
        ) { completion in
            guard let tiffData = self.screenshot.image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else {
                completion(nil, false, nil)
                return nil
            }

            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("Pawshot_\(Int(Date().timeIntervalSince1970))")
                .appendingPathExtension("png")

            do {
                try pngData.write(to: tempURL)
                completion(tempURL, true, nil)
            } catch {
                completion(nil, false, error)
            }
            return nil
        }

        return provider
    }

    private var buttonOverlay: some View {
        HStack(spacing: 4) {
            actionButton(icon: "doc.on.doc", label: "Copy") {
                ClipboardService.shared.copyToClipboard(screenshot.image)
                FloatingPreviewService.shared.dismiss()
            }

            actionButton(icon: "square.and.arrow.down", label: "Save") {
                let format = AppSettings.shared.selectedExportFormat
                _ = try? FileExportService.shared.save(screenshot.image, format: format)
                FloatingPreviewService.shared.dismiss()
            }

            actionButton(icon: "pencil", label: "Edit") {
                FloatingPreviewService.shared.dismiss()
                coordinator.openEditor(for: screenshot)
            }

            actionButton(icon: "xmark", label: "Close") {
                FloatingPreviewService.shared.dismiss()
            }
        }
        .padding(6)
    }

    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .help(label)
    }
}
