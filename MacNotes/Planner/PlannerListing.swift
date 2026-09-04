nonisolated enum PlannerListing: CaseIterable, Hashable, Sendable {
    case day
    case unscheduled

    var name: String {
        switch self {
        case .day: "Day"
        case .unscheduled: "Unscheduled"
        }
    }

    var nothingThere: String {
        switch self {
        case .day: "Nothing on this day"
        case .unscheduled: "Nothing waiting for a Day"
        }
    }

    var invitation: String {
        switch self {
        case .day: "Add a task to this day"
        case .unscheduled: "Add a task without a Day"
        }
    }
}
