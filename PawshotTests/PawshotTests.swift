import XCTest
@testable import Pawshot

final class PawshotTests: XCTestCase {

    func testCaptureModeProperties() {
        XCTAssertEqual(CaptureMode.area.displayName, "Capture Area")
        XCTAssertEqual(CaptureMode.window.displayName, "Capture Window")
        XCTAssertEqual(CaptureMode.fullScreen.displayName, "Capture Full Screen")
    }

    func testExportFormatProperties() {
        XCTAssertEqual(ExportFormat.png.fileExtension, "png")
        XCTAssertEqual(ExportFormat.jpg.fileExtension, "jpg")
        XCTAssertEqual(ExportFormat.webp.fileExtension, "webp")
    }

    func testAnnotationBoundingRect() {
        var annotation = Annotation(tool: .rectangle)
        annotation.startPoint = CGPoint(x: 10, y: 20)
        annotation.endPoint = CGPoint(x: 100, y: 200)

        let rect = annotation.boundingRect
        XCTAssertEqual(rect.origin.x, 10)
        XCTAssertEqual(rect.origin.y, 20)
        XCTAssertEqual(rect.width, 90)
        XCTAssertEqual(rect.height, 180)
    }

    func testAnnotationBoundingRectReversed() {
        var annotation = Annotation(tool: .rectangle)
        annotation.startPoint = CGPoint(x: 100, y: 200)
        annotation.endPoint = CGPoint(x: 10, y: 20)

        let rect = annotation.boundingRect
        XCTAssertEqual(rect.origin.x, 10)
        XCTAssertEqual(rect.origin.y, 20)
        XCTAssertEqual(rect.width, 90)
        XCTAssertEqual(rect.height, 180)
    }

    func testScreenshotCreation() {
        let image = NSImage(size: NSSize(width: 100, height: 100))
        let screenshot = Screenshot(image: image, captureMode: .area, rect: CGRect(x: 0, y: 0, width: 100, height: 100))

        XCTAssertEqual(screenshot.captureMode, .area)
        XCTAssertNotNil(screenshot.rect)
        XCTAssertNotNil(screenshot.id)
    }

    func testDateFormatterFormat() {
        let formatter = DateFormatter.screenshotFormatter
        let date = formatter.date(from: "2024-01-15 at 10.30.00")
        XCTAssertNotNil(date)
    }
}
