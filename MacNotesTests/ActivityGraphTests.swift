import CoreGraphics
import Foundation
import SwiftUI
import Testing

@testable import MacNotes

@MainActor
final class ActivityGraphTests {
    private let folder = TemporaryFolder()
    private let shown = Day(year: 2026, month: 9, day: 15)

    deinit {
        folder.discard()
    }

    private func store(completions: Int) -> TaskStore {
        let store = TaskStore(file: JSONFile(name: "tasks.json", in: folder.url), saveDelay: 60)
        for number in 0..<completions {
            store.add(
                Task(title: "Done \(number)", day: shown, completedOn: shown))
        }
        return store
    }

    private func ink(_ completions: Int) throws -> Int {
        let pixels = try Pixels(
            ActivityGraph(tasks: store(completions: completions), month: shown),
            width: ActivityGraph.width, height: 140)

        var total = 0
        for x in 0..<pixels.width {
            for y in 0..<pixels.height {
                total += Int(pixels.alpha(atX: CGFloat(x), y: CGFloat(y)))
            }
        }
        return total
    }

    @Test func aDayWithCompletionsIsShadedMoreThanAnEmptyOne() throws {
        #expect(try ink(1) > ink(0))
    }

    @Test func moreCompletionsShadeTheDayFurther() throws {
        #expect(try ink(1) < ink(2))
        #expect(try ink(2) < ink(4))
    }

    @Test func theCeilingIsFixedSoAHugeDayIsNotShadedFurther() throws {
        #expect(try ink(ActivityGraph.ceiling) == ink(ActivityGraph.ceiling + 4))
        #expect(try ink(ActivityGraph.ceiling) == ink(40))
    }

    @Test func aMonthIsLaidOutAsWholeWeeks() throws {
        let pixels = try Pixels(
            ActivityGraph(tasks: store(completions: 0), month: shown),
            width: ActivityGraph.width, height: 140)

        #expect(pixels.height == 140)
    }
}
