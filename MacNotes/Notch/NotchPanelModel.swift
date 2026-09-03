import Observation

@MainActor
@Observable
final class NotchPanelModel {
    private(set) var state: NotchPanelState

    init(state: NotchPanelState = .hidden) {
        self.state = state
    }

    func cursorMoved(isOver: Bool) {
        state = isOver ? .expanded : .hidden
    }
}
