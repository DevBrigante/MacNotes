import CoreGraphics
import SwiftUI
import Testing

@testable import MacNotes

struct ProgressTrayTests {
    private let outline = CGRect(x: 0, y: 0, width: 62, height: 27)

    @Test func sweepsDownOneSideAlongTheBottomAndUpTheOther() {
        let corners = corners(of: TrayOutline(cornerRadius: 5).path(in: outline))

        #expect(
            corners == [
                CGPoint(x: 0, y: 0),
                CGPoint(x: 0, y: 22),
                CGPoint(x: 5, y: 27),
                CGPoint(x: 57, y: 27),
                CGPoint(x: 62, y: 22),
                CGPoint(x: 62, y: 0),
            ])
    }

    @Test func isOneOpenSweepRatherThanALoop() {
        let path = TrayOutline(cornerRadius: 5).path(in: outline)
        let corners = corners(of: path)

        #expect(corners.filter { $0.y == outline.minY }.count == 2)
        #expect(corners.first != corners.last)
    }

    @Test func aCornerTooBigForTheOutlineIsCutDownToFit() {
        let path = TrayOutline(cornerRadius: 500).path(in: outline)

        #expect(outline.contains(path.boundingRect))
    }

    @Test func anEmptyTrayDrawsNothing() {
        let path = TrayOutline(cornerRadius: 5).path(in: outline)

        #expect(path.trimmedPath(from: 0, to: 0).isEmpty)
    }

    @Test func aTrayHalfGrownHasNotReachedTheFarSide() {
        let path = TrayOutline(cornerRadius: 5).path(in: outline)

        let half = path.trimmedPath(from: 0, to: 0.5).boundingRect
        #expect(half.maxX < outline.maxX)
        #expect(outline.contains(half))
    }

    @Test func aFullTrayReachesBothTopCorners() {
        let path = TrayOutline(cornerRadius: 5).path(in: outline)

        let full = path.trimmedPath(from: 0, to: 1).boundingRect
        #expect(full.minX == outline.minX)
        #expect(full.maxX == outline.maxX)
    }

    private func corners(of path: Path) -> [CGPoint] {
        var corners: [CGPoint] = []
        path.forEach { element in
            switch element {
            case .move(let to): corners.append(to)
            case .line(let to): corners.append(to)
            case .quadCurve(let to, _): corners.append(to)
            case .curve(let to, _, _): corners.append(to)
            case .closeSubpath: break
            }
        }
        return corners
    }
}
