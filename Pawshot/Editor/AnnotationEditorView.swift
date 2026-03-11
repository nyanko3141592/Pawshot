import SwiftUI

struct AnnotationEditorView: View {
    @ObservedObject var state: EditorState

    var body: some View {
        VStack(spacing: 0) {
            AnnotationToolbar(state: state)
                .padding(.horizontal)
                .padding(.vertical, 8)

            Divider()

            AnnotationCanvas(state: state)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            bottomBar
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var bottomBar: some View {
        HStack {
            Button("Cancel") {
                NSApp.keyWindow?.close()
            }

            Spacer()

            Button("Copy") {
                if let image = state.renderFinalImage() {
                    ClipboardService.shared.copyToClipboard(image)
                }
            }

            Button("Save As...") {
                Task {
                    if let image = state.renderFinalImage() {
                        let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
                        _ = try? await FileExportService.shared.saveWithPanel(nsImage)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
