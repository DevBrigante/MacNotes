import Foundation
import SwiftUI
import Testing

@testable import MacNotes

@MainActor
final class TodayPanelTests {
    private let folder = TemporaryFolder()
    private let width: CGFloat = 464
    private let height: CGFloat = 260

    deinit {
        folder.discard()
    }

    private func store(_ planned: [Task] = []) -> TaskStore {
        let store = TaskStore(file: JSONFile(name: "tasks.json", in: folder.url), saveDelay: 60)
        planned.forEach(store.add)
        return store
    }

    private func idle() -> FocusSessionModel {
        FocusSessionModel(now: { 0 }, tick: 60, workspace: NotificationCenter())
    }

    private func panel(_ tasks: TaskStore) -> TodayPanel {
        TodayPanel(model: NotchPanelModel(), tasks: tasks, sessions: idle())
    }

    private func rows(_ tasks: TaskStore) -> TodayRows {
        TodayRows(
            tasks: tasks, sessions: idle(), listed: tasks.onTheDay(.today()), day: .today(),
            choosing: .constant(nil))
    }

    @Test func theRowsWriteTheTasksTheDayIsCarrying() throws {
        let pixels = try Pixels(
            rows(store([Task(title: "Book the flight", day: .today())])), width: width)

        #expect(pixels.written(across: 1...Int(width) - 2, down: 1...pixels.height - 2))
    }

    @Test func theRowsGrowByOneRowForEachTask() throws {
        let one = try Pixels(
            rows(store([Task(title: "Book the flight", day: .today())])), width: width)
        let three = try Pixels(
            rows(
                store([
                    Task(title: "Book the flight", day: .today()),
                    Task(title: "Renew the passport", day: .today()),
                    Task(title: "Read the manual", day: .today()),
                ])), width: width)

        #expect(one.height == Int(TodayRows.rowHeight))
        #expect(three.height == Int(TodayRows.rowHeight) * 3)
    }

    @Test func aPanelWithNothingForTodayStillOffersTheAddField() throws {
        let pixels = try Pixels(panel(store()), width: width, height: height)

        #expect(
            pixels.written(across: 1...Int(width) - 2, down: Int(height) - 30...Int(height) - 2))
    }

    @Test func theEmptyStateCountsWhatIsStillWaitingForADay() throws {
        let quiet = try Pixels(panel(store()), width: width, height: height)
        let waiting = try Pixels(
            panel(
                store([
                    Task(title: "Read the manual"),
                    Task(title: "Sharpen the knives"),
                ])), width: width, height: height)

        #expect(waiting.writtenRows().count > quiet.writtenRows().count)
    }

    @Test func aTaskThatBelongsToAnotherDayNeverReachesTheRows() throws {
        let elsewhere = Day(year: 2020, month: 1, day: 1)
        let tasks = store([
            Task(title: "Book the flight", day: elsewhere),
            Task(title: "Read the manual"),
        ])

        #expect(tasks.onTheDay(.today()).isEmpty)

        let pixels = try Pixels(panel(tasks), width: width, height: height)
        let quiet = try Pixels(
            panel(store([Task(title: "Read the manual")])), width: width, height: height)

        #expect(pixels.writtenRows() == quiet.writtenRows())
    }
}
