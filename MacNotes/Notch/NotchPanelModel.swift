import Observation

/// Drives the Notch Panel's state from the cursor.
///
/// The Panel rests Hidden and opens under the cursor. Collapsed waits on a
/// running Focus Session to put it there, and there are no Sessions yet — so
/// nothing reaches that state at runtime, though the Panel knows how to draw it.
@MainActor
@Observable
final class NotchPanelModel {

    /// What the Panel is showing right now.
    private(set) var state: NotchPanelState

    init(state: NotchPanelState = .hidden) {
        self.state = state
    }

    /// The cursor moved; `isOver` is whether it is now on the Panel.
    func cursorMoved(isOver: Bool) {
        state = isOver ? .expanded : .hidden
    }
}
