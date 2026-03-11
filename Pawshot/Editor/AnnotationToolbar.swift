import SwiftUI

struct AnnotationToolbar: View {
    @ObservedObject var state: EditorState

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AnnotationTool.allCases) { tool in
                Button {
                    state.selectedTool = tool
                } label: {
                    Image(systemName: tool.systemImage)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.bordered)
                .tint(state.selectedTool == tool ? .accentColor : .secondary)
                .help(tool.displayName)
            }

            Divider()
                .frame(height: 24)
                .padding(.horizontal, 4)

            ColorPicker("", selection: Binding(
                get: { Color(nsColor: state.selectedColor) },
                set: { state.selectedColor = NSColor($0) }
            ))
            .labelsHidden()
            .frame(width: 28)

            Divider()
                .frame(height: 24)
                .padding(.horizontal, 4)

            Slider(value: $state.selectedLineWidth, in: 1...10, step: 1)
                .frame(width: 80)
                .help("Line Width")

            Spacer()

            Button {
                state.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(state.undoStack.isEmpty)
            .help("Undo")

            Button {
                state.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(state.redoStack.isEmpty)
            .help("Redo")

            Button(role: .destructive) {
                state.clearAll()
            } label: {
                Image(systemName: "trash")
            }
            .disabled(state.annotations.isEmpty)
            .help("Clear All")
        }
    }
}
