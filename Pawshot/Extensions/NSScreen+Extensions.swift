import AppKit

extension NSScreen {
    var scaleFactor: CGFloat {
        backingScaleFactor
    }

    static var primaryScreen: NSScreen? {
        screens.first
    }

    var isMainScreen: Bool {
        self == NSScreen.main
    }
}
