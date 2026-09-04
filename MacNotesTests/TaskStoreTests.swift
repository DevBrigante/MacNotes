import Foundation
import Testing

@testable import MacNotes

private let yesterday = Day(year: 2026, month: 9, day: 2)
private let today = Day(year: 2026, month: 9, day: 3)
private let tomorrow = Day(year: 2026, month: 9, day: 4)
private let saveDelay: TimeInterval = 0.2

@MainActor
final class TaskStoreTests {
    private let folder = TemporaryFolder()
    private let store: TaskStore

    init() {
        store = TaskStore(file: JSONFile(name: "tasks.json", in: folder.url), saveDelay: saveDelay)
    }

    deinit {
        folder.discard()
    }

    private var onDisk: JSONFile<[Task]>.Reading {
        JSONFile<[Task]>(name: "tasks.json", in: folder.url).read(on: today)
    }

    private func plant(_ tasks: [Task]) throws {
        try JSONFile<[Task]>(name: "tasks.json", in: folder.url).write(tasks)
    }

    private func letTheWritesSettle() {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: saveDelay * 3))
    }

    @Test func startsWithNothingWhenThereIsNoFileYet() {
        store.load(on: today)

        #expect(store.tasks.isEmpty)
        #expect(store.corruption == nil)
    }

    @Test func keepsWhatItWasGivenAcrossARestart() {
        store.load(on: today)
        store.add(Task(title: "Book the flight", notes: "Aisle seat", day: today))
        store.save()

        let restarted = TaskStore(
            file: JSONFile(name: "tasks.json", in: folder.url), saveDelay: saveDelay)
        restarted.load(on: today)

        #expect(restarted.tasks == store.tasks)
    }

    @Test func givesUpPassedDaysAsItLoads() throws {
        var done = Task(title: "Renew the passport", day: yesterday)
        done.complete(on: yesterday)
        try plant([
            Task(title: "Book the flight", day: yesterday),
            done,
            Task(title: "Pack", day: tomorrow),
        ])

        store.load(on: today)

        #expect(store.tasks[0].isUnscheduled)
        #expect(store.tasks[1].day == yesterday)
        #expect(store.tasks[2].day == tomorrow)
    }

    @Test func writesBackTheDaysItGaveUp() throws {
        try plant([Task(title: "Book the flight", day: yesterday)])

        store.load(on: today)
        letTheWritesSettle()

        #expect(onDisk == .value(store.tasks))
        #expect(folder.text(of: "tasks.json")?.contains(yesterday.text) == false)
    }

    @Test func givesUpPassedDaysWhenTheDayTurns() {
        store.load(on: today)
        store.add(Task(title: "Book the flight", day: Day(year: 2020, month: 1, day: 1)))

        NotificationCenter.default.post(name: .NSCalendarDayChanged, object: nil)
        letTheWritesSettle()

        #expect(store.tasks[0].isUnscheduled)
    }

    @Test func aChangeWaitsBeforeItIsWritten() {
        store.load(on: today)
        store.add(Task(title: "Book the flight"))

        #expect(folder.holds("tasks.json") == false)

        letTheWritesSettle()

        #expect(onDisk == .value(store.tasks))
    }

    @Test func aBurstOfChangesIsWrittenOnceItEnds() {
        store.load(on: today)

        for title in ["Book the flight", "Pack", "Renew the passport"] {
            store.add(Task(title: title))
        }

        #expect(folder.holds("tasks.json") == false)

        letTheWritesSettle()

        #expect(store.tasks.count == 3)
        #expect(onDisk == .value(store.tasks))
    }

    @Test func savesAtOnceWhenAskedTo() {
        store.load(on: today)
        store.add(Task(title: "Book the flight"))

        store.save()

        #expect(onDisk == .value(store.tasks))
    }

    @Test func completingATaskIsKept() {
        store.load(on: today)
        var task = Task(title: "Book the flight", day: today)
        store.add(task)

        task.complete(on: today)
        store.update(task)
        store.save()

        #expect(onDisk == .value([task]))
    }

    @Test func surfacesAFileItCouldNotReadAndStartsThatFileClean() {
        folder.plant("{ this was never JSON", as: "tasks.json")

        store.load(on: today)

        #expect(store.tasks.isEmpty)
        #expect(
            store.corruption
                == Corruption(file: "tasks.json", setAside: "tasks.corrupt-2026-09-03.json"))
    }

    @Test func neverOverwritesAFileItCouldNotSetAside() {
        folder.plant("{ this was never JSON", as: "tasks.json")
        folder.lockAgainstWriting()

        store.load(on: today)
        store.add(Task(title: "Book the flight"))
        store.save()

        #expect(store.corruption == Corruption(file: "tasks.json", setAside: nil))
        #expect(folder.text(of: "tasks.json") == "{ this was never JSON")
    }

    @Test func saysSoRatherThanLosingAWriteQuietly() {
        folder.plant("{ this was never JSON", as: "tasks.json")
        folder.lockAgainstWriting()

        store.load(on: today)
        store.add(Task(title: "Book the flight"))
        store.save()

        #expect(store.couldNotSave)
    }

    @Test func aWriteThatLandsClearsTheAlarm() {
        store.load(on: today)
        store.add(Task(title: "Book the flight"))

        store.save()

        #expect(store.couldNotSave == false)
    }

    @Test func quickCaptureGivesANewTaskTheDayItWasCapturedOn() throws {
        store.load(on: today)

        let captured = try #require(store.capture("Book the flight", on: today))

        #expect(captured.day == today)
        #expect(captured.title == "Book the flight")
        #expect(store.tasks == [captured])
    }

    @Test func quickCaptureTrimsTheTitleAndRefusesABlankOne() {
        store.load(on: today)

        #expect(store.capture("  Book the flight  ", on: today)?.title == "Book the flight")
        #expect(store.capture("   ", on: today) == nil)
        #expect(store.capture("", on: today) == nil)
        #expect(store.tasks.count == 1)
    }

    @Test func completingATaskRecordsTheDayItWasDoneOn() {
        store.load(on: today)
        store.add(Task(title: "Book the flight", day: yesterday))

        store.complete(store.tasks[0], on: today)

        #expect(store.tasks[0].completedOn == today)
        #expect(store.tasks[0].day == yesterday)
    }

    @Test func completingATaskTwiceKeepsTheFirstDay() {
        store.load(on: today)
        store.add(Task(title: "Book the flight", day: today))

        store.complete(store.tasks[0], on: yesterday)
        store.complete(store.tasks[0], on: today)

        #expect(store.tasks[0].completedOn == yesterday)
    }

    @Test func aCompletionReachesDiskOnItsOwn() {
        store.load(on: today)
        store.add(Task(title: "Book the flight", day: today))
        store.complete(store.tasks[0], on: today)

        letTheWritesSettle()

        #expect(onDisk == .value(store.tasks))
    }

    @Test func theDaysTasksAreTheOnlyOnesItAnswersWith() {
        store.load(on: today)
        store.add(Task(title: "Book the flight", day: today))
        store.add(Task(title: "Renew the passport", day: tomorrow))
        store.add(Task(title: "Read the manual"))

        #expect(store.onTheDay(today).map(\.title) == ["Book the flight"])
    }

    @Test func theDaysTasksKeepTheOrderTheyWereGivenIn() {
        store.load(on: today)
        store.add(Task(title: "Book the flight", day: today))
        store.add(Task(title: "Renew the passport", day: today))
        store.complete(store.tasks[0], on: today)

        #expect(store.onTheDay(today).map(\.title) == ["Book the flight", "Renew the passport"])
    }

    @Test func whatIsUnscheduledIsWorkStillWaitingForADay() {
        store.load(on: today)
        store.add(Task(title: "Book the flight", day: today))
        store.add(Task(title: "Read the manual"))
        store.add(Task(title: "Sharpen the knives"))
        store.complete(store.tasks[2], on: today)

        #expect(store.unscheduled.map(\.title) == ["Read the manual"])
    }
}

@MainActor
final class TaskStoreOrderTests {
    private let folder = TemporaryFolder()
    private let today = Day.today()

    deinit {
        folder.discard()
    }

    private func store(_ planned: [Task] = []) -> TaskStore {
        let store = TaskStore(file: JSONFile(name: "tasks.json", in: folder.url), saveDelay: 60)
        planned.forEach(store.add)
        return store
    }

    @Test func aTaskDraggedDownTakesTheOrderOfTheOneItPassed() {
        let tasks = store([
            Task(title: "First", day: today),
            Task(title: "Second", day: today),
            Task(title: "Third", day: today),
        ])

        tasks.move(within: tasks.onTheDay(today), from: 0, to: 2)

        #expect(tasks.onTheDay(today).map(\.title) == ["Second", "Third", "First"])
    }

    @Test func aTaskDraggedUpDoesTheSameInReverse() {
        let tasks = store([
            Task(title: "First", day: today),
            Task(title: "Second", day: today),
            Task(title: "Third", day: today),
        ])

        tasks.move(within: tasks.onTheDay(today), from: 2, to: 0)

        #expect(tasks.onTheDay(today).map(\.title) == ["Third", "First", "Second"])
    }

    @Test func reorderingADayLeavesEveryOtherTaskWhereItWas() {
        let elsewhere = Day(year: 2030, month: 1, day: 1)
        let tasks = store([
            Task(title: "First", day: today),
            Task(title: "Elsewhere", day: elsewhere),
            Task(title: "Second", day: today),
        ])

        tasks.move(within: tasks.onTheDay(today), from: 0, to: 1)

        #expect(tasks.tasks.map(\.title) == ["Second", "Elsewhere", "First"])
    }

    @Test func aMoveThatGoesNowhereChangesNothing() {
        let tasks = store([Task(title: "First", day: today), Task(title: "Second", day: today)])

        tasks.move(within: tasks.onTheDay(today), from: 0, to: 0)
        tasks.move(within: tasks.onTheDay(today), from: 5, to: 0)

        #expect(tasks.onTheDay(today).map(\.title) == ["First", "Second"])
    }

    @Test func anAllottedTimeIsKeptAgainstTheTask() {
        let task = Task(title: "Book the flight", day: today)
        let tasks = store([task])

        #expect(tasks.task(task.id)?.allotted == .standard)

        tasks.allot(AllottedTime(minutes: 45), to: task.id)

        #expect(tasks.task(task.id)?.allotted.minutes == 45)
    }

    @Test func completionsAreCountedForTheDayTheyLandedOn() {
        let yesterday = Day(year: 2026, month: 9, day: 3)
        let one = Task(title: "First", day: today)
        let two = Task(title: "Second", day: today)
        let tasks = store([one, two, Task(title: "Third", day: today)])

        tasks.complete(one, on: today)
        tasks.complete(two, on: today)

        #expect(tasks.completions(on: today) == 2)
        #expect(tasks.completions(on: yesterday) == 0)
    }
}
