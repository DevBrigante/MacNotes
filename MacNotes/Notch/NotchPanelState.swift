nonisolated enum NotchPanelState: CaseIterable, Equatable, Sendable {
    case hidden
    case collapsed
    case expanded

    var name: String {
        switch self {
        case .hidden: "Hidden"
        case .collapsed: "Collapsed"
        case .expanded: "Expanded"
        }
    }
}
