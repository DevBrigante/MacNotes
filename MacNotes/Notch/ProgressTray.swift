import AppKit
import SwiftUI

struct ProgressTray: View {
    let grown: Double
    let reach: CGFloat
    let panelCornerRadius: CGFloat

    @State private var accent = ProgressTray.systemAccent()

    private let lineWidth: CGFloat = 2.5
    private let inset: CGFloat = 5

    var body: some View {
        HStack(spacing: 0) {
            half
            Spacer(minLength: 0)
            half.scaleEffect(x: -1)
        }
        .padding(inset)
        .onReceive(
            NotificationCenter.default.publisher(for: NSColor.systemColorsDidChangeNotification)
        ) { _ in
            accent = Self.systemAccent()
        }
    }

    private var half: some View {
        TrayOutline(cornerRadius: panelCornerRadius - inset)
            .trim(from: 0, to: grown)
            .stroke(accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .frame(width: reach - 2 * inset)
    }

    private static func systemAccent() -> Color {
        let accent = NSColor.controlAccentColor
        return Color(nsColor: accent.usingColorSpace(.sRGB) ?? accent)
    }
}

nonisolated struct TrayOutline: Shape {
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let radius = min(cornerRadius, rect.width, rect.height)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.maxY),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}
