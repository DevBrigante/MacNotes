nonisolated enum PlannerListing: CaseIterable, Hashable, Sendable {
    case day
    case unscheduled

    var name: String {
        switch self {
        case .day: "Day"
        case .unscheduled: "Unscheduled"
        }
    }
}
