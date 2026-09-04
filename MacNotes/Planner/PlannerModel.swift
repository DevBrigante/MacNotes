import Foundation
import Observation

@MainActor
@Observable
final class PlannerModel {
    var listing: PlannerListing = .day
    var editing: Task.ID?
    private(set) var justCompleted: Set<Task.ID> = []
    var month: Day
    private(set) var selected: Day

    @ObservationIgnored let tasks: TaskStore
    @ObservationIgnored let sessions: FocusSessionModel

    init(tasks: TaskStore, sessions: FocusSessionModel, today: Day = .today()) {
        self.tasks = tasks
        self.sessions = sessions
        selected = today
        month = today.firstOfItsMonth
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
    }

    func stepTheMonth(by steps: Int) {
        month = month.monthStepped(by: steps)
    }

    func show(_ today: Day = .today()) {
        pick(today)
        editing = nil
        justCompleted = []
    }

    func capture(_ title: String) {
        tasks.capture(title, on: capturesOn)
    }

    func toggleCompletion(of task: Task, on today: Day = .today()) {
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

    func countOn(_ day: Day) -> Int {
        tasks.onTheDay(day).count
    }
}
