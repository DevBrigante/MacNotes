import CoreGraphics
import Foundation
import SwiftUI
import Testing

struct Pixels {
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

    @MainActor
    init(_ view: some View, width: CGFloat, height: CGFloat? = nil) throws {
        let sized = height.map { view.frame(width: width, height: $0) }
        let renderer = ImageRenderer(content: sized ?? view.frame(width: width))
        renderer.scale = 1
        try self.init(try #require(renderer.cgImage))
    }

    func alpha(atX x: CGFloat, y: CGFloat) -> UInt8 {
        pixel(atX: x, y: y).alpha
    }

    func pixel(
        atX x: CGFloat, y: CGFloat
    ) -> (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        let column = min(max(Int(x), 0), width - 1)
        let row = min(max(Int(y), 0), height - 1)
        let start = (row * width + column) * 4
        return (bytes[start], bytes[start + 1], bytes[start + 2], bytes[start + 3])
    }

    func isLit(atX x: CGFloat, y: CGFloat) -> Bool {
        let pixel = pixel(atX: x, y: y)
        return pixel.red > 80 && pixel.green > 80 && pixel.blue > 80
    }

    func written(across xs: ClosedRange<Int>, down ys: ClosedRange<Int>) -> Bool {
        xs.contains { x in ys.contains { y in isLit(atX: CGFloat(x), y: CGFloat(y)) } }
    }

    func writtenRows() -> [Int] {
        (0..<height).filter { y in
            (0..<width).contains { x in isLit(atX: CGFloat(x), y: CGFloat(y)) }
        }
    }
}
