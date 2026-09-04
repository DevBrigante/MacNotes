import Foundation
import SwiftUI
import Testing

@testable import MacNotes

@MainActor
final class TodayPanelTests {
    private let folder = TemporaryFolder()
    private let width: CGFloat = 464
    private let height: CGFloat = 140
    private let todoWidth: CGFloat = 464 - ActivityGraph.width

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

    private func cards(_ tasks: TaskStore) -> TodayCards {
        TodayCards(
            model: NotchPanelModel(), tasks: tasks, sessions: idle(),
            listed: tasks.listing(on: .today(), keeping: []), day: .today(),
            accent: .blue, allotting: nil, onAllot: { _ in }, onAct: {}, scroller: nil,
            justCompleted: .constant([]))
    }

    @Test func theCardsWriteTheTasksTheDayIsCarrying() throws {
        let pixels = try Pixels(
            cards(store([Task(title: "Book the flight", day: .today())])), width: todoWidth)

        #expect(pixels.written(across: 1...Int(todoWidth) - 2, down: 1...pixels.height - 2))
    }

    @Test func theCardsGrowByOneForEachTask() throws {
        let one = try Pixels(
            cards(store([Task(title: "Book the flight", day: .today())])), width: todoWidth)
        let three = try Pixels(
            cards(
                store([
                    Task(title: "Book the flight", day: .today()),
                    Task(title: "Renew the passport", day: .today()),
                    Task(title: "Read the manual", day: .today()),
                ])), width: todoWidth)

        #expect(one.height == Int(TodayPanel.cardHeight) + 4)
        #expect(
            three.height
                == Int(TodayPanel.cardHeight) * 3 + Int(TodayPanel.cardGap) * 2 + 4)
    }

    @Test func aPanelWithNothingForTodaySaysSoUnderTheHeading() throws {
        let pixels = try Pixels(panel(store()), width: width, height: height)

        #expect(pixels.written(across: 1...Int(todoWidth) - 2, down: 40...100))
    }

    @Test func aTaskThatBelongsToAnotherDayNeverReachesTheCards() throws {
        let elsewhere = Day(year: 2020, month: 1, day: 1)
        let tasks = store([
            Task(title: "Book the flight", day: elsewhere),
            Task(title: "Read the manual"),
        ])

        #expect(tasks.listing(on: .today(), keeping: []).isEmpty)
    }

    @Test func theActivityColumnIsHeadedBesideTheList() throws {
        let pixels = try Pixels(panel(store()), width: width, height: height)
        let column = Int(width - ActivityGraph.width)

        #expect(pixels.written(across: column + 2...Int(width) - 2, down: 1...22))
    }

    @Test func aCompletedTaskDropsToTheFootWhileThePanelIsStillOpen() {
        let done = Task(title: "Renew the passport", day: .today())
        let waiting = Task(title: "Book the flight", day: .today())
        let tasks = store([done, waiting])
        tasks.complete(done, on: .today())

        let listed = tasks.listing(on: .today(), keeping: [done.id])

        #expect(listed.map(\.title) == ["Book the flight", "Renew the passport"])
    }

    @Test func aCompletedTaskIsGoneTheNextTimeThePanelOpens() {
        let done = Task(title: "Renew the passport", day: .today())
        let tasks = store([done, Task(title: "Book the flight", day: .today())])
        tasks.complete(done, on: .today())

        #expect(tasks.listing(on: .today(), keeping: []).map(\.title) == ["Book the flight"])
        #expect(tasks.task(done.id)?.isCompleted == true)
    }
}

struct TodayCardsDragTests {
    private let stride = TodayPanel.cardStride

    @Test func aCardsHomeIsTheCentreOfItsSlot() {
        #expect(TodayCards.home(of: 0) == TodayPanel.cardInset + TodayPanel.cardHeight / 2)
        #expect(TodayCards.home(of: 3) == TodayCards.home(of: 0) + 3 * stride)
    }

    @Test func theCursorLandsOnTheCardItIsOver() {
        #expect(TodayCards.landing(of: TodayCards.home(of: 0), among: 4) == 0)
        #expect(TodayCards.landing(of: TodayCards.home(of: 1), among: 4) == 1)
        #expect(TodayCards.landing(of: TodayCards.home(of: 3), among: 4) == 3)
    }

    @Test func theLastCardCanReachTheFirstSlot() {
        #expect(TodayCards.landing(of: TodayCards.home(of: 0), among: 4) == 0)
        #expect(TodayCards.landing(of: 0, among: 4) == 0)
        #expect(TodayCards.landing(of: -500, among: 4) == 0)
    }

    @Test func theCursorNeverLandsPastEitherEnd() {
        #expect(TodayCards.landing(of: 5000, among: 4) == 3)
        #expect(TodayCards.landing(of: -5000, among: 4) == 0)
        #expect(TodayCards.landing(of: 5000, among: 1) == 0)
        #expect(TodayCards.landing(of: 5000, among: 0) == 0)
    }

    @Test func aCardLiftedToItsOwnHomeDoesNotMove() {
        #expect(TodayCards.landing(of: TodayCards.home(of: 2) + 1, among: 4) == 2)
        #expect(TodayCards.landing(of: TodayCards.home(of: 2) - 1, among: 4) == 2)
    }

    @Test func theCursorWalksTheListOnlyFromTheEdgeBands() {
        let viewport: CGFloat = 92

        #expect(TodayCards.walking(at: 46, within: viewport) == 0)
        #expect(TodayCards.walking(at: TodayPanel.cardBand + 1, within: viewport) == 0)
        #expect(TodayCards.walking(at: viewport - TodayPanel.cardBand - 1, within: viewport) == 0)
    }

    @Test func theTopBandWalksItUpAndTheBottomBandWalksItDown() {
        let viewport: CGFloat = 92

        #expect(TodayCards.walking(at: 0, within: viewport) == -1)
        #expect(TodayCards.walking(at: -40, within: viewport) == -1)
        #expect(TodayCards.walking(at: viewport, within: viewport) == 1)
        #expect(TodayCards.walking(at: viewport + 40, within: viewport) == 1)
    }

    @Test func nothingWalksBeforeTheListHasBeenMeasured() {
        #expect(TodayCards.walking(at: 0, within: 0) == 0)
        #expect(TodayCards.walking(at: 500, within: 0) == 0)
    }
}
