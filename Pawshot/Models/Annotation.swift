import AppKit
import Foundation

struct Annotation: Identifiable {
    let id: UUID
    var tool: AnnotationTool
    var color: NSColor
    var lineWidth: CGFloat
    var startPoint: CGPoint
    var endPoint: CGPoint
    var points: [CGPoint]
    var text: String?
    var fontSize: CGFloat
    var isCompleted: Bool

    init(
        tool: AnnotationTool,
        color: NSColor = .red,
        lineWidth: CGFloat = 2.0,
        startPoint: CGPoint = .zero,
        endPoint: CGPoint = .zero,
        text: String? = nil,
        fontSize: CGFloat = 16.0
    ) {
        self.id = UUID()
        self.tool = tool
        self.color = color
        self.lineWidth = lineWidth
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.points = []
        self.text = text
        self.fontSize = fontSize
        self.isCompleted = false
    }

    var boundingRect: CGRect {
        CGRect(
            x: min(startPoint.x, endPoint.x),
            y: min(startPoint.y, endPoint.y),
            width: abs(endPoint.x - startPoint.x),
            height: abs(endPoint.y - startPoint.y)
        )
    }
}
