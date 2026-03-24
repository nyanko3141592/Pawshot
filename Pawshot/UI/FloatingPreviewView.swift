import SwiftUI

struct FloatingPreviewView: View {
    let screenshot: Screenshot
    let coordinator: CaptureCoordinator
    let previewSize: NSSize
    let previewID: UUID

    @State private var isHovering = false
    @State private var ocrInProgress = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Use resized image to avoid layout mismatch
            Image(nsImage: screenshot.image.resized(to: previewSize))
                .frame(width: previewSize.width, height: previewSize.height)
                .clipped()

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
        }
    }

    private var buttonOverlay: some View {
        HStack(spacing: 4) {
            actionButton(icon: "doc.on.doc", label: "Copy") {
                ClipboardService.shared.copyToClipboard(screenshot.image)
                FloatingPreviewService.shared.dismiss(id: previewID)
            }

            actionButton(icon: "square.and.arrow.down", label: "Save") {
                let format = AppSettings.shared.selectedExportFormat
                _ = try? FileExportService.shared.save(screenshot.image, format: format)
                FloatingPreviewService.shared.dismiss(id: previewID)
            }

            actionButton(icon: "text.viewfinder", label: "OCR") {
                ocrInProgress = true
                Task {
                    let success = await OCRService.shared.recognizeTextAndCopy(from: screenshot.image)
                    await MainActor.run {
                        ocrInProgress = false
                        if success {
                            FloatingPreviewService.shared.dismiss(id: previewID)
                        } else {
                            NSSound.beep()
                        }
                    }
                }
            }

            actionButton(icon: "pencil", label: "Edit") {
                FloatingPreviewService.shared.dismiss(id: previewID)
                coordinator.openEditor(for: screenshot)
            }

            actionButton(icon: "xmark", label: "Close") {
                FloatingPreviewService.shared.dismiss(id: previewID)
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
