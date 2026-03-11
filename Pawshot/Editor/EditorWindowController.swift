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
        let windowWidth = max(min(imageSize.width + 40, screenFrame.width * 0.9), 500)
        let windowHeight = max(min(imageSize.height + toolbarHeight, screenFrame.height * 0.9), 400)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Pawshot Editor"
        window.contentViewController = hostingController
        window.center()
        window.isReleasedWhenClosed = false

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
