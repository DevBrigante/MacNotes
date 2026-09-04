import Foundation

nonisolated struct Task: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var title: String
    var notes: String?
    var day: Day?
    var completedOn: Day?

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        day: Day? = nil,
        completedOn: Day? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.day = day
        self.completedOn = completedOn
    }

    var isCompleted: Bool {
        completedOn != nil
    }

    var isUnscheduled: Bool {
        day == nil
    }

    mutating func complete(on day: Day) {
        completedOn = day
    }

    func droppingAPassedDay(on today: Day) -> Task {
        guard let day, day < today, isCompleted == false else { return self }
        var task = self
        task.day = nil
        return task
    }
}
