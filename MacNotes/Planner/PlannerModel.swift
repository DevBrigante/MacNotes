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
    @ObservationIgnored let calendar: CalendarEvents
    @ObservationIgnored private let notices: NotificationCenter
    @ObservationIgnored private var dayTurned: (any NSObjectProtocol)?

    init(
        tasks: TaskStore,
        sessions: FocusSessionModel,
        calendar: CalendarEvents? = nil,
        today: Day = .today(),
        notices: NotificationCenter = .default
    ) {
        self.tasks = tasks
        self.sessions = sessions
        self.calendar = calendar ?? CalendarEvents()
        self.today = today
        self.notices = notices
        selected = today
        month = today.firstOfItsMonth
        self.calendar.load(on: today)
        watchForTheDayTurning()
    }

    deinit {
        dayTurned.map(notices.removeObserver)
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
        calendar.load(on: day)
    }

    func show() {
        pick(today)
    }

    func theDayTurned(to today: Day) {
        self.today = today
        show()
    }

    @discardableResult
    func capture(_ title: String, notes: String? = nil) -> Task? {
        tasks.capture(title, notes: notes, on: capturesOn)
    }

    func connectCalendar() async {
        await calendar.connect()
    }

    func openCalendarSettings() {
        calendar.openSettings()
    }

    func refreshCalendar() {
        calendar.load(on: selected)
    }

    func toggleCompletion(of task: Task) {
        if task.isCompleted {
            justCompleted.remove(task.id)
            tasks.undoTheCompletion(of: task.id)
        } else {
            justCompleted.insert(task.id)
            tasks.complete(task, on: today)
            sessions.endTheSession(on: task.id)
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
        dayTurned = notices.addObserver(
            forName: .NSCalendarDayChanged, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.theDayTurned(to: .today()) }
        }
    }
}
