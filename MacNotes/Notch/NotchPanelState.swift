/// The Notch Panel's three states.
///
/// `hidden` and `collapsed` are the two resting states — which one applies
/// depends on whether a Focus Session is running. `expanded` is reached from
/// either of them, by the cursor.
nonisolated enum NotchPanelState: CaseIterable, Equatable, Sendable {
    /// Drawn entirely within the notch's silhouette: the display looks untouched.
    case hidden
    /// The strip flanking the notch.
    case collapsed
    /// The fuller interface, hanging below the strip.
    case expanded

    /// The state's name in the glossary's spelling.
    var name: String {
        switch self {
        case .hidden: "Hidden"
        case .collapsed: "Collapsed"
        case .expanded: "Expanded"
        }
    }
}
