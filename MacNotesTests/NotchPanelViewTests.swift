import CoreGraphics
import Foundation
import SwiftUI
import Testing

@testable import MacNotes

@MainActor
struct NotchPanelViewTests {
    private let physical = NotchMetrics(
        screenFrame: CGRect(x: 0, y: 0, width: 1512, height: 982),
        notchRect: CGRect(x: 656, y: 945, width: 200, height: 37),
        hasPhysicalNotch: true
    )

    private let simulated = NotchMetrics(
        screenFrame: CGRect(x: 0, y: 0, width: 2560, height: 1440),
        notchRect: CGRect(x: 1180, y: 1416, width: 200, height: 24),
        hasPhysicalNotch: false
    )

    @Test func nothingIsDrawnOverTheCamera() throws {
        let model = collapsed()
        let pixels = try render(model, on: physical)
        let gap = physical.notchGap(for: model.state)

        #expect(pixels.alpha(atX: gap.midX, y: gap.midY) == 0)
        #expect(pixels.alpha(atX: gap.minX + 1, y: gap.midY) == 0)
        #expect(pixels.alpha(atX: gap.maxX - 1, y: gap.midY) == 0)
    }

    @Test func bothFlanksAreDrawnOn() throws {
        let model = collapsed()
        let pixels = try render(model, on: physical)
        let gap = physical.notchGap(for: model.state)

        #expect(pixels.alpha(atX: gap.minX / 2, y: gap.midY) == 255)
        #expect(pixels.alpha(atX: (gap.maxX + CGFloat(pixels.width)) / 2, y: gap.midY) == 255)
    }

    @Test func hiddenDrawsNothingAtAllWhereTheNotchIsPhysical() throws {
        let pixels = try render(NotchPanelModel(), on: physical)

        for x in stride(from: 1.0, to: Double(pixels.width) - 1, by: 4) {
            for y in stride(from: 1.0, to: Double(pixels.height) - 1, by: 4) {
                #expect(pixels.alpha(atX: x, y: y) == 0)
            }
        }
    }

    @Test func expandedLeavesTheWholeMenuBarStripAlone() throws {
        let model = expanded()
        let pixels = try render(model, on: physical)
        let strip = physical.notchGap(for: model.state)

        for x in stride(from: 1.0, to: Double(pixels.width) - 1, by: 4) {
            #expect(pixels.alpha(atX: x, y: strip.midY) == 0)
        }
    }

    @Test func collapsedDrawsTheSimulatedNotchAsOneStripWithItsFlanks() throws {
        let model = collapsed()
        let pixels = try render(model, on: simulated)
        let gap = simulated.notchGap(for: model.state)

        #expect(pixels.alpha(atX: gap.midX, y: gap.midY) == 255)
        #expect(pixels.alpha(atX: gap.minX + 1, y: gap.midY) == 255)
        #expect(pixels.alpha(atX: gap.maxX - 1, y: gap.midY) == 255)
    }

    @Test func expandedKeepsTheSimulatedNotchAndNothingElseInTheStrip() throws {
        let model = expanded()
        let pixels = try render(model, on: simulated)
        let strip = simulated.notchGap(for: model.state)

        #expect(pixels.alpha(atX: strip.midX, y: strip.midY) == 255)
        #expect(pixels.alpha(atX: strip.minX / 2, y: strip.midY) == 0)
        #expect(pixels.alpha(atX: (strip.maxX + CGFloat(pixels.width)) / 2, y: strip.midY) == 0)
    }

    @Test func hiddenMarksTheSimulatedNotchAndNothingElse() throws {
        let pixels = try render(NotchPanelModel(), on: simulated)
        let centre = (x: Double(pixels.width) / 2, y: Double(pixels.height) / 2)

        #expect(pixels.alpha(atX: centre.x, y: centre.y) == 255)

        for x in stride(from: 1.0, to: Double(pixels.width) - 1, by: 4)
        where abs(x - centre.x) > 12 {
            for y in stride(from: 1.0, to: Double(pixels.height) - 1, by: 4) {
                #expect(pixels.alpha(atX: x, y: y) == 0)
            }
        }
    }

    private func collapsed() -> NotchPanelModel {
        NotchPanelModel(state: .collapsed)
    }

    private func expanded() -> NotchPanelModel {
        let model = NotchPanelModel()
        model.cursorMoved(isOver: true)
        return model
    }

    private func render(_ model: NotchPanelModel, on metrics: NotchMetrics) throws -> Pixels {
        let frame = metrics.panelFrame(for: model.state)
        let renderer = ImageRenderer(
            content: NotchPanelView(metrics: metrics, model: model)
                .frame(width: frame.width, height: frame.height)
        )
        renderer.scale = 1
        return try Pixels(try #require(renderer.cgImage))
    }

    private struct Pixels {
        let width: Int
        let height: Int
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

        func alpha(atX x: CGFloat, y: CGFloat) -> UInt8 {
            let column = min(max(Int(x), 0), width - 1)
            let row = min(max(Int(y), 0), height - 1)
            return bytes[(row * width + column) * 4 + 3]
        }
    }
}
