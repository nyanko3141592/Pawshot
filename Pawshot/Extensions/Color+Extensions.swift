import AppKit
import SwiftUI

extension Color {
    static let annotationColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .white, .black,
    ]
}

extension NSColor {
    var hexString: String {
        guard let rgb = usingColorSpace(.sRGB) else { return "#000000" }
        return String(format: "#%02X%02X%02X",
                      Int(rgb.redComponent * 255),
                      Int(rgb.greenComponent * 255),
                      Int(rgb.blueComponent * 255))
    }
}
