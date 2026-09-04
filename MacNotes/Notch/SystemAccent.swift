import AppKit
import SwiftUI

nonisolated enum SystemAccent {
    static func colour() -> Color {
        let accent = NSColor.controlAccentColor
        return Color(nsColor: accent.usingColorSpace(.sRGB) ?? accent)
    }
}
