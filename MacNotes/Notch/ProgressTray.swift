import AppKit
import SwiftUI

struct ProgressTray: View {
    let grown: Double
    let panelCornerRadius: CGFloat

    @State private var accent = SystemAccent.colour()

    private let lineWidth: CGFloat = 2.5
    private let inset: CGFloat = 5

    var body: some View {
        TrayOutline(cornerRadius: panelCornerRadius - inset)
            .trim(from: 0, to: grown)
            .stroke(accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .padding(inset)
            .onReceive(
                NotificationCenter.default.publisher(for: NSColor.systemColorsDidChangeNotification)
            ) { _ in
                accent = SystemAccent.colour()
            }
    }
}

nonisolated struct TrayOutline: Shape {
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let radius = min(cornerRadius, rect.width / 2, rect.height)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.maxY),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY - radius),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}
