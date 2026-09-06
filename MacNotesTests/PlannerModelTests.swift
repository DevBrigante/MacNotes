import Foundation
import Testing

@testable import MacNotes

private let today = Day(year: 2026, month: 9, day: 4)
private let tomorrow = Day(year: 2026, month: 9, day: 5)

@MainActor
final class PlannerModelTests {
    private let folder = TemporaryFolder()
    private let tasks: TaskStore
    private let sessions: FocusSessionModel
    private let planner: PlannerModel

    init() {
        tasks = TaskStore(file: JSONFile(name: "tasks.json", in: folder.url), saveDelay: 60)
        sessions = FocusSessionModel(now: { 0 }, tick: 60, workspace: NotificationCenter())
        planner = PlannerModel(tasks: tasks, sessions: sessions, today: today)
    }

    deinit {
        folder.discard()
    }

    @Test func opensOnTodayAndOnTheDaysOwnList() {
        #expect(planner.selected == today)
        #expect(planner.month == Day(year: 2026, month: 9, day: 1))
        #expect(planner.listing == .day)
    }

    @Test func theDaysListIsWhatThatDayCarries() {
        tasks.add(Task(title: "Book the flight", day: today))
        tasks.add(Task(title: "Renew the passport", day: tomorrow))
        tasks.add(Task(title: "Read the manual"))

        #expect(planner.listed.map(\.title) == ["Book the flight"])

        planner.pick(tomorrow)

        #expect(planner.listed.map(\.title) == ["Renew the passport"])
    }

    @Test func theUnscheduledListIsTheOneTheNotchPanelCounts() {
        tasks.add(Task(title: "Book the flight", day: today))
        tasks.add(Task(title: "Read the manual"))
        let done = Task(title: "Sharpen the knives")
        tasks.add(done)
        tasks.complete(done, on: today)

        planner.listing = .unscheduled

        #expect(planner.listed.map(\.title) == tasks.unscheduled.map(\.title))
        #expect(planner.listed.map(\.title) == ["Read the manual"])
    }

    @Test func pickingADayBringsItsMonthWithItAndLeavesTheUnscheduled() {
        planner.listing = .unscheduled

        planner.pick(Day(year: 2026, month: 12, day: 24))

        #expect(planner.selected == Day(year: 2026, month: 12, day: 24))
        #expect(planner.month == Day(year: 2026, month: 12, day: 1))
        #expect(planner.listing == .day)
    }

    @Test func browsingAnotherMonthLeavesTheSelectedDayWhereItIs() {
        planner.month = planner.month.monthStepped(by: 2)

        #expect(planner.month == Day(year: 2026, month: 11, day: 1))
        #expect(planner.selected == today)
    }

    @Test func theTodayButtonComesBackFromWhereverItWas() {
        planner.pick(Day(year: 2027, month: 3, day: 9))
        planner.editing = UUID()

        planner.show()

        #expect(planner.selected == today)
        #expect(planner.month == Day(year: 2026, month: 9, day: 1))
        #expect(planner.editing == nil)
    }

    @Test func theDayTurningMovesTheWindowOntoTheNewToday() {
        planner.theDayTurned(to: tomorrow)

        #expect(planner.today == tomorrow)
        #expect(planner.selected == tomorrow)
    }

    @Test func aCompletionMadeHereLandsOnTheDayItWasMadeOn() {
        let task = Task(title: "Book the flight", day: today)
        tasks.add(task)
        planner.theDayTurned(to: tomorrow)

        planner.toggleCompletion(of: task)

        #expect(tasks.task(task.id)?.completedOn == tomorrow)
    }

    @Test func captureLandsOnTheDayOnShowAndNowhereAtAllInTheUnscheduled() {
        planner.pick(tomorrow)
        planner.capture("Book the flight")

        planner.listing = .unscheduled
        planner.capture("Read the manual")

        #expect(tasks.onTheDay(tomorrow).map(\.title) == ["Book the flight"])
        #expect(tasks.unscheduled.map(\.title) == ["Read the manual"])
    }

    @Test func anUnscheduledTaskStaysOnScreenLongEnoughToUntickIt() throws {
        let task = Task(title: "Read the manual")
        tasks.add(task)
        planner.listing = .unscheduled

        planner.toggleCompletion(of: task)

        #expect(tasks.unscheduled.isEmpty)
        #expect(planner.listed.map(\.title) == ["Read the manual"])

        planner.toggleCompletion(of: try #require(tasks.task(task.id)))

        #expect(tasks.unscheduled.map(\.title) == ["Read the manual"])
    }

    @Test func anUnscheduledTaskTickedIsGoneTheNextTimeThePlannerOpens() {
        let task = Task(title: "Read the manual")
        tasks.add(task)
        planner.listing = .unscheduled
        planner.toggleCompletion(of: task)

        planner.show()
        planner.listing = .unscheduled

        #expect(planner.listed.isEmpty)
        #expect(tasks.task(task.id)?.isCompleted == true)
    }

    @Test func pickingAnotherDayLetsATickedTaskGoAndClosesAnyNotes() {
        let task = Task(title: "Read the manual")
        tasks.add(task)
        planner.listing = .unscheduled
        planner.toggleCompletion(of: task)
        planner.editing = task.id

        planner.pick(tomorrow)
        planner.listing = .unscheduled

        #expect(planner.listed.isEmpty)
        #expect(planner.editing == nil)
    }

    @Test func aCompletionCanBeMadeAndTakenBack() throws {
        let task = Task(title: "Book the flight", day: today)
        tasks.add(task)

        planner.toggleCompletion(of: task)

        #expect(tasks.task(task.id)?.completedOn == today)

        planner.toggleCompletion(of: try #require(tasks.task(task.id)))

        #expect(tasks.task(task.id)?.isCompleted == false)
    }

    @Test func deletingTheTaskASessionIsRunningOnEndsTheSession() {
        let going = Task(title: "Book the flight", day: today)
        tasks.add(going)
        sessions.startOrPause(going)

        planner.delete(going)

        #expect(tasks.task(going.id) == nil)
        #expect(sessions.session == nil)
    }

    @Test func deletingTheTaskWhoseNotesAreOpenClosesThem() {
        let going = Task(title: "Book the flight", day: today)
        tasks.add(going)
        planner.editing = going.id

        planner.delete(going)

        #expect(planner.editing == nil)
    }

    @Test func deletingATaskLeavesTheSessionOnAnotherOneAlone() {
        let running = Task(title: "Book the flight", day: today)
        let going = Task(title: "Renew the passport", day: today)
        tasks.add(running)
        tasks.add(going)
        sessions.startOrPause(running)

        planner.delete(going)

        #expect(sessions.session?.task == running.id)
    }

    @Test func aRowDraggedDownLandsWhereItWasDropped() {
        ["First", "Second", "Third"].forEach { tasks.add(Task(title: $0, day: today)) }

        planner.move(IndexSet(integer: 0), to: 3)

        #expect(planner.listed.map(\.title) == ["Second", "Third", "First"])
    }

    @Test func aRowDraggedUpLandsWhereItWasDropped() {
        ["First", "Second", "Third"].forEach { tasks.add(Task(title: $0, day: today)) }

        planner.move(IndexSet(integer: 2), to: 0)

        #expect(planner.listed.map(\.title) == ["Third", "First", "Second"])
    }

    @Test func reorderingTheUnscheduledMovesTheSameOneSequence() {
        ["First", "Second", "Third"].forEach { tasks.add(Task(title: $0)) }
        planner.listing = .unscheduled

        planner.move(IndexSet(integer: 0), to: 2)

        #expect(planner.listed.map(\.title) == ["Second", "First", "Third"])
    }
}
