import Foundation

nonisolated struct Task: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var title: String
    var notes: String?
    var day: Day?
    var completedOn: Day?
    var allotted: AllottedTime

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        day: Day? = nil,
        completedOn: Day? = nil,
        allotted: AllottedTime = .standard
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.day = day
        self.completedOn = completedOn
        self.allotted = allotted
    }

    init(from decoder: any Decoder) throws {
        let stored = try decoder.container(keyedBy: CodingKeys.self)
        id = try stored.decode(UUID.self, forKey: .id)
        title = try stored.decode(String.self, forKey: .title)
        notes = try stored.decodeIfPresent(String.self, forKey: .notes)
        day = try stored.decodeIfPresent(Day.self, forKey: .day)
        completedOn = try stored.decodeIfPresent(Day.self, forKey: .completedOn)
        allotted = try stored.decodeIfPresent(AllottedTime.self, forKey: .allotted) ?? .standard
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
