import AppKit
import SwiftUI

final class EditorState: ObservableObject {
    let screenshot: Screenshot

    @Published var annotations: [Annotation] = []
    @Published var currentAnnotation: Annotation?
    @Published var selectedTool: AnnotationTool = .arrow
    @Published var selectedColor: NSColor = .red
    @Published var selectedLineWidth: CGFloat = 2.0
    @Published var selectedFontSize: CGFloat = 16.0

    @Published var undoStack: [[Annotation]] = []
    @Published var redoStack: [[Annotation]] = []

    init(screenshot: Screenshot) {
        self.screenshot = screenshot
    }

    /// Next number to assign to a number-stamp annotation. Counted from existing
    /// annotations so Undo/Redo automatically rewinds the counter without any
    /// extra state to keep in sync.
    var nextNumber: Int {
        annotations.filter { $0.tool == .number }.count + 1
    }

    func beginAnnotation(at point: CGPoint) {
        var annotation = Annotation(
            tool: selectedTool,
            color: selectedColor,
            lineWidth: selectedLineWidth,
            startPoint: point,
            endPoint: point,
            fontSize: selectedFontSize
        )

        if selectedTool == .highlighter {
            annotation.points.append(point)
        }

        if selectedTool == .text {
            annotation.text = promptForText()
            if annotation.text == nil { return }
            annotation.isCompleted = true
            pushUndo()
            annotations.append(annotation)
            return
        }

        if selectedTool == .number {
            // Click-only stamp: place immediately with the next number.
            annotation.text = String(nextNumber)
            annotation.isCompleted = true
            pushUndo()
            annotations.append(annotation)
            return
        }

        currentAnnotation = annotation
    }

    func continueAnnotation(at point: CGPoint) {
        guard var annotation = currentAnnotation else { return }

        annotation.endPoint = point

        if annotation.tool == .highlighter {
            annotation.points.append(point)
        }

        currentAnnotation = annotation
    }

    func endAnnotation(at point: CGPoint) {
        guard var annotation = currentAnnotation else { return }

        annotation.endPoint = point
        annotation.isCompleted = true

        if annotation.tool == .highlighter {
            annotation.points.append(point)
        }

        // Only add if it has meaningful size
        let dx = abs(annotation.endPoint.x - annotation.startPoint.x)
        let dy = abs(annotation.endPoint.y - annotation.startPoint.y)
        if dx > 2 || dy > 2 || !annotation.points.isEmpty {
            pushUndo()
            annotations.append(annotation)
        }

        currentAnnotation = nil
    }

    func undo() {
        guard !undoStack.isEmpty else { return }
        redoStack.append(annotations)
        annotations = undoStack.removeLast()
    }

    func redo() {
        guard !redoStack.isEmpty else { return }
        undoStack.append(annotations)
        annotations = redoStack.removeLast()
    }

    func clearAll() {
        guard !annotations.isEmpty else { return }
        pushUndo()
        annotations.removeAll()
    }

    private func pushUndo() {
        undoStack.append(annotations)
        redoStack.removeAll()
    }

    func renderFinalImage() -> CGImage? {
        AnnotationRenderer.renderFinalImage(screenshot: screenshot, annotations: annotations)
    }

    private func promptForText() -> String? {
        let alert = NSAlert()
        alert.messageText = "Enter Text"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        textField.placeholderString = "Enter annotation text..."
        alert.accessoryView = textField

        let response = alert.runModal()
        if response == .alertFirstButtonReturn && !textField.stringValue.isEmpty {
            return textField.stringValue
        }
        return nil
    }
}
