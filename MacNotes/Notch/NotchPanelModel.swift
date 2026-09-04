import Observation

@MainActor
@Observable
final class NotchPanelModel {
    private(set) var state: NotchPanelState = .hidden
    private(set) var isAllotting = false

    @ObservationIgnored var layoutChanged: (@MainActor () -> Void)?

    @ObservationIgnored private var cursorIsOver = false
    @ObservationIgnored private var captureHasTheKeyboard = false
    @ObservationIgnored private var taskIsBeingDragged = false
    @ObservationIgnored private var sessionIsUnderway = false

    func cursorMoved(isOver: Bool) {
        cursorIsOver = isOver
        settle()
    }

    func captureChanged(hasTheKeyboard: Bool) {
        captureHasTheKeyboard = hasTheKeyboard
        settle()
    }

    func dragChanged(isDragging: Bool) {
        taskIsBeingDragged = isDragging
        settle()
    }

    func allottingChanged(isAllotting: Bool) {
        self.isAllotting = isAllotting
        settle()
    }

    func sessionChanged(isUnderway: Bool) {
        sessionIsUnderway = isUnderway
        settle()
    }

    private func settle() {
        if cursorIsOver || captureHasTheKeyboard || taskIsBeingDragged || isAllotting {
            state = .expanded
        } else {
            isAllotting = false
            state = sessionIsUnderway ? .collapsed : .hidden
        }
        layoutChanged?()
    }
}
