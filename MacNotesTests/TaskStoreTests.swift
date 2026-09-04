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
}
