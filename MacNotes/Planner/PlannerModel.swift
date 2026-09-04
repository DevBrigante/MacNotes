import Foundation
import Observation

@MainActor
@Observable
final class PlannerModel {
    var listing: PlannerListing = .day
    var editing: Task.ID?
    var month: Day
    private(set) var selected: Day
    private(set) var today: Day
    private(set) var justCompleted: Set<Task.ID> = []

    @ObservationIgnored let tasks: TaskStore
    @ObservationIgnored let sessions: FocusSessionModel
    @ObservationIgnored private var dayTurned: (any NSObjectProtocol)?

    init(tasks: TaskStore, sessions: FocusSessionModel, today: Day = .today()) {
        self.tasks = tasks
        self.sessions = sessions
        self.today = today
        selected = today
        month = today.firstOfItsMonth
        watchForTheDayTurning()
    }

    deinit {
        dayTurned.map(NotificationCenter.default.removeObserver)
    }

    var listed: [Task] {
        switch listing {
        case .day: tasks.plan(on: selected)
        case .unscheduled: tasks.waiting(keeping: justCompleted)
        }
    }

    var capturesOn: Day? {
        listing == .day ? selected : nil
    }

    func pick(_ day: Day) {
        selected = day
        month = day.firstOfItsMonth
        listing = .day
        editing = nil
        justCompleted = []
    }

    func show() {
        pick(today)
    }

    func theDayTurned(to today: Day) {
        self.today = today
        show()
    }

    func capture(_ title: String) {
        tasks.capture(title, on: capturesOn)
    }

    func toggleCompletion(of task: Task) {
        if task.isCompleted {
            justCompleted.remove(task.id)
            tasks.undoTheCompletion(of: task.id)
        } else {
            justCompleted.insert(task.id)
            tasks.complete(task, on: today)
        }
    }

    func delete(_ task: Task) {
        sessions.endTheSession(on: task.id)
        if editing == task.id { editing = nil }
        justCompleted.remove(task.id)
        tasks.delete(task.id)
    }

    func move(_ picked: IndexSet, to landing: Int) {
        guard let from = picked.first else { return }
        tasks.move(within: listed, from: from, to: landing > from ? landing - 1 : landing)
    }

    private func watchForTheDayTurning() {
        dayTurned = NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.theDayTurned(to: .today()) }
        }
    }
}
