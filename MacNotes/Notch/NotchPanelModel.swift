import Observation

@MainActor
@Observable
final class NotchPanelModel {
    private(set) var state: NotchPanelState = .hidden

    @ObservationIgnored private var cursorIsOver = false
    @ObservationIgnored private var captureHasTheKeyboard = false
    @ObservationIgnored private var sessionIsUnderway = false

    func cursorMoved(isOver: Bool) {
        cursorIsOver = isOver
        settle()
    }

    func captureChanged(hasTheKeyboard: Bool) {
        captureHasTheKeyboard = hasTheKeyboard
        settle()
    }

    func sessionChanged(isUnderway: Bool) {
        sessionIsUnderway = isUnderway
        settle()
    }

    private func settle() {
        if cursorIsOver || captureHasTheKeyboard {
            state = .expanded
        } else {
            state = sessionIsUnderway ? .collapsed : .hidden
        }
    }
}
