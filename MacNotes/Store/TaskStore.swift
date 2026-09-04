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
