import AppKit
import SwiftUI

final class EditorWindowController: NSWindowController {
    private static var activeControllers: [EditorWindowController] = []

    convenience init(screenshot: Screenshot) {
        let editorState = EditorState(screenshot: screenshot)
        let editorView = AnnotationEditorView(state: editorState)
        let hostingController = NSHostingController(rootView: editorView)

        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let imageSize = screenshot.image.size  // Already in points

        let toolbarHeight: CGFloat = 100
        let maxWidth = screenFrame.width * 0.85
        let maxHeight = screenFrame.height * 0.85
        let windowWidth = max(min(imageSize.width + 40, maxWidth), 500)
        let windowHeight = max(min(imageSize.height + toolbarHeight, maxHeight), 400)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Pawshot Editor"
        window.contentViewController = hostingController
        window.contentMinSize = NSSize(width: 500, height: 400)
        window.isReleasedWhenClosed = false

        // Center within visible screen area and ensure window stays within bounds
        window.center()
        var frame = window.frame
        frame.origin.x = max(frame.origin.x, screenFrame.origin.x)
        frame.origin.y = max(frame.origin.y, screenFrame.origin.y)
        if frame.maxX > screenFrame.maxX {
            frame.origin.x = screenFrame.maxX - frame.width
        }
        if frame.maxY > screenFrame.maxY {
            frame.origin.y = screenFrame.maxY - frame.height
        }
        window.setFrame(frame, display: true)

        self.init(window: window)

        EditorWindowController.activeControllers.append(self)

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            EditorWindowController.activeControllers.removeAll { $0 === self }
        }
    }
}
