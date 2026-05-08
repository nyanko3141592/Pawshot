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
        // Cap default window size to ~60% of the visible screen so big captures
        // (Retina 4K/5K) don't dominate the desktop. AnnotationCanvas already
        // aspect-fits the image into its view, so a smaller window just shrinks
        // the displayed image — no functionality lost. The user can still drag
        // the window larger via the resize handle.
        let maxWidth = screenFrame.width * 0.60
        let maxHeight = screenFrame.height * 0.60
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
