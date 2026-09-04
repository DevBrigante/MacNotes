import Foundation
import Observation

@MainActor
@Observable
final class TaskStore {
    private(set) var tasks: [Task] = []
    private(set) var corruption: Corruption?
    private(set) var couldNotSave = false

    @ObservationIgnored private let file: JSONFile<[Task]>
    @ObservationIgnored private let saveDelay: TimeInterval
    @ObservationIgnored private var pendingSave: Timer?
    @ObservationIgnored private var dayTurned: (any NSObjectProtocol)?

    init(file: JSONFile<[Task]>, saveDelay: TimeInterval = 1) {
        self.file = file
        self.saveDelay = saveDelay
        watchForTheDayTurning()
    }

    deinit {
        pendingSave?.invalidate()
        dayTurned.map(NotificationCenter.default.removeObserver)
    }

    func load(on today: Day) {
        tasks = []
        corruption = nil

        switch file.read(on: today) {
        case .value(let stored):
            tasks = stored
        case .blank:
            break
        case .unreadable(let found):
            corruption = found
        }

        giveUpPassedDays(on: today)
    }

    func add(_ task: Task) {
        tasks.append(task)
        scheduleSave()
    }

    func update(_ task: Task) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = task
        scheduleSave()
    }

    func delete(_ id: Task.ID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks.remove(at: index)
        scheduleSave()
    }

    @discardableResult
    func capture(_ title: String, on day: Day?) -> Task? {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard title.isEmpty == false else { return nil }

        let task = Task(title: title, day: day)
        add(task)
        return task
    }

    func complete(_ task: Task, on day: Day) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }),
            tasks[index].isCompleted == false
        else { return }

        tasks[index].complete(on: day)
        scheduleSave()
    }

    func undoTheCompletion(of id: Task.ID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }),
            tasks[index].isCompleted
        else { return }

        tasks[index].completedOn = nil
        scheduleSave()
    }

    func give(_ day: Day?, to id: Task.ID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        guard tasks[index].day != day else { return }
        tasks[index].day = day
        scheduleSave()
    }

    func note(_ text: String, on id: Task.ID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        let written = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let kept = written.isEmpty ? nil : text
        guard tasks[index].notes != kept else { return }
        tasks[index].notes = kept
        scheduleSave()
    }

    func allot(_ time: AllottedTime, to id: Task.ID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        guard tasks[index].allotted != time else { return }
        tasks[index].allotted = time
        scheduleSave()
    }

    func move(within listed: [Task], from: Int, to: Int) {
        guard listed.indices.contains(from), listed.indices.contains(to), from != to else {
            return
        }
        let slots = listed.compactMap { listing in
            tasks.firstIndex { $0.id == listing.id }
        }
        guard slots.count == listed.count else { return }

        var reordered = listed
        reordered.insert(reordered.remove(at: from), at: to)

        for (slot, task) in zip(slots, reordered) {
            tasks[slot] = task
        }
        scheduleSave()
    }

    func task(_ id: Task.ID) -> Task? {
        tasks.first { $0.id == id }
    }

    func completions(on day: Day) -> Int {
        tasks.filter { $0.completedOn == day }.count
    }

    func onTheDay(_ day: Day) -> [Task] {
        tasks.filter { $0.day == day }
    }

    func listing(on day: Day, keeping completed: Set<Task.ID>) -> [Task] {
        unfinishedFirst(
            onTheDay(day).filter { $0.isCompleted == false || completed.contains($0.id) })
    }

    func plan(on day: Day) -> [Task] {
        unfinishedFirst(onTheDay(day))
    }

    func waiting(keeping completed: Set<Task.ID>) -> [Task] {
        unfinishedFirst(
            tasks.filter {
                $0.isUnscheduled && ($0.isCompleted == false || completed.contains($0.id))
            })
    }

    private func unfinishedFirst(_ listed: [Task]) -> [Task] {
        listed.filter { $0.isCompleted == false } + listed.filter(\.isCompleted)
    }

    var unscheduled: [Task] {
        waiting(keeping: [])
    }

    func save() {
        pendingSave?.invalidate()
        pendingSave = nil

        do {
            try file.write(tasks)
            couldNotSave = false
        } catch {
            couldNotSave = true
        }
    }

    private func scheduleSave() {
        pendingSave?.invalidate()
        let timer = Timer(timeInterval: saveDelay, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.save() }
        }
        RunLoop.main.add(timer, forMode: .common)
        pendingSave = timer
    }

    private func giveUpPassedDays(on today: Day) {
        let unscheduled = tasks.map { $0.droppingAPassedDay(on: today) }
        guard unscheduled != tasks else { return }
        tasks = unscheduled
        scheduleSave()
    }

    private func watchForTheDayTurning() {
        dayTurned = NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.giveUpPassedDays(on: .today()) }
        }
    }
}
