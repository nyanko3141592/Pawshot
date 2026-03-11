import AppKit
import CoreGraphics

final class LegacyCaptureEngine {

    func captureFullScreen(displayID: CGDirectDisplayID) -> CGImage? {
        CGDisplayCreateImage(displayID)
    }

    func captureArea(displayID: CGDirectDisplayID, rect: CGRect) -> CGImage? {
        CGDisplayCreateImage(displayID, rect: rect)
    }

    func captureWindow(windowID: CGWindowID) -> CGImage? {
        let options: CGWindowImageOption = AppSettings.shared.captureWindowShadow
            ? [.boundsIgnoreFraming, .bestResolution]
            : [.boundsIgnoreFraming, .bestResolution, .nominalResolution]

        return CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            windowID,
            options
        )
    }
}
