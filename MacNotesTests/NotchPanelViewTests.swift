import CoreGraphics
import Foundation
import SwiftUI
import Testing

@testable import MacNotes

/// Renders the Notch Panel and reads the pixels back. The placement tests prove
/// the window lands on the notch; this proves the drawing stays off it.
@MainActor
struct NotchPanelViewTests {

    private let metrics = NotchMetrics(
        screenFrame: CGRect(x: 0, y: 0, width: 1512, height: 982),
        notchRect: CGRect(x: 656, y: 945, width: 200, height: 37),
        hasPhysicalNotch: true
    )

    @Test func nothingIsDrawnOverTheCamera() throws {
        let model = collapsed()
        let pixels = try render(model)
        let gap = metrics.notchGap(for: model.state)

        #expect(pixels.alpha(atX: gap.midX, y: gap.midY) == 0)
        #expect(pixels.alpha(atX: gap.minX + 1, y: gap.midY) == 0)
        #expect(pixels.alpha(atX: gap.maxX - 1, y: gap.midY) == 0)
    }

    @Test func bothFlanksAreDrawnOn() throws {
        let model = collapsed()
        let pixels = try render(model)
        let gap = metrics.notchGap(for: model.state)

        #expect(pixels.alpha(atX: gap.minX / 2, y: gap.midY) == 255)
        #expect(pixels.alpha(atX: (gap.maxX + CGFloat(pixels.width)) / 2, y: gap.midY) == 255)
    }

    @Test func hiddenDrawsNothingAtAll() throws {
        let pixels = try render(NotchPanelModel())

        for x in stride(from: 2.0, to: Double(pixels.width) - 2, by: 8) {
            #expect(pixels.alpha(atX: x, y: 8) == 0)
        }
    }

    @Test func expandedLeavesTheWholeMenuBarStripAlone() throws {
        let model = NotchPanelModel()
        model.cursorMoved(isOver: true)
        let pixels = try render(model)
        let strip = metrics.notchGap(for: model.state)

        // Expanded hangs below the menu bar instead of reaching across it, so
        // the whole strip — camera and menu bar alike — stays untouched.
        for x in stride(from: 1.0, to: Double(pixels.width) - 1, by: 4) {
            #expect(pixels.alpha(atX: x, y: strip.midY) == 0)
        }
    }

    // MARK: Rendering

    /// Collapsed is out of the cursor's reach until a Focus Session can put the
    /// Panel there, but the Panel still has to draw it correctly.
    private func collapsed() -> NotchPanelModel {
        NotchPanelModel(state: .collapsed)
    }

    private func render(_ model: NotchPanelModel) throws -> Pixels {
        let frame = metrics.panelFrame(for: model.state)
        let renderer = ImageRenderer(
            content: NotchPanelView(metrics: metrics, model: model)
                .frame(width: frame.width, height: frame.height)
        )
        renderer.scale = 1
        return try Pixels(try #require(renderer.cgImage))
    }

    /// The rendered panel, addressable one pixel at a time.
    private struct Pixels {
        let width: Int
        private let height: Int
        private let bytes: [UInt8]

        init(_ image: CGImage) throws {
            width = image.width
            height = image.height

            var buffer = [UInt8](repeating: 0, count: width * height * 4)
            let context = try #require(
                CGContext(
                    data: &buffer,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: width * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                )
            )
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            bytes = buffer
        }

        /// Alpha at a point in the panel's own space, origin top-left.
        func alpha(atX x: CGFloat, y: CGFloat) -> UInt8 {
            let column = min(max(Int(x), 0), width - 1)
            let row = min(max(Int(y), 0), height - 1)
            return bytes[(row * width + column) * 4 + 3]
        }
    }
}
