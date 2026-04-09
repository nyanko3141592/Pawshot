import SwiftUI

struct FloatingPreviewView: View {
    let screenshot: Screenshot
    let coordinator: CaptureCoordinator
    let previewSize: NSSize
    let previewID: UUID

    @State private var isHovering = false
    @State private var ocrInProgress = false

    /// Actual image display size (may be narrower than previewSize for tall images)
    private var imageDisplaySize: NSSize {
        let imageSize = screenshot.image.size
        let maxWidth: CGFloat = 200
        let maxHeight: CGFloat = 140
        let scale = min(maxWidth / max(imageSize.width, 1), maxHeight / max(imageSize.height, 1), 1.0)
        return NSSize(
            width: ceil(imageSize.width * scale),
            height: ceil(imageSize.height * scale)
        )
    }

    var body: some View {
        ZStack {
            // Use resized image to avoid layout mismatch
            Image(nsImage: screenshot.image.resized(to: imageDisplaySize))
                .frame(width: imageDisplaySize.width, height: imageDisplaySize.height)
                .clipped()
                .frame(width: previewSize.width, height: previewSize.height)

            // Always visible close button at top-right
            VStack {
                HStack {
                    Spacer()
                    Button {
                        FloatingPreviewService.shared.dismiss(id: previewID)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                            .background(Color.black.opacity(0.55))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Close")
                }
                Spacer()
            }
            .padding(5)

            // Action buttons on hover at bottom
            if isHovering {
                VStack {
                    Spacer()
                    HStack(spacing: 3) {
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
                    }
                    .padding(6)
                }
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
