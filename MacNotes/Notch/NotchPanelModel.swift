import Observation

@MainActor
@Observable
final class NotchPanelModel {
    private(set) var state: NotchPanelState = .hidden
    private(set) var isAllotting = false
    private(set) var revealedTask: Task.ID?

    @ObservationIgnored var layoutChanged: (@MainActor () -> Void)?
    @ObservationIgnored var plannerAsked: (@MainActor () -> Void)?

    @ObservationIgnored private var cursorIsOver = false
    @ObservationIgnored private var captureHasTheKeyboard = false
    @ObservationIgnored private var taskIsBeingDragged = false
    @ObservationIgnored private var sessionIsUnderway = false
    @ObservationIgnored private var showsSessionReadout = false
    @ObservationIgnored private var plannerIsOpen = false

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

    func askForThePlanner() {
        plannerAsked?()
    }

    func plannerChanged(isOpen: Bool) {
        plannerIsOpen = isOpen
        if isOpen == false { cursorIsOver = false }
        settle()
    }

    func sessionChanged(isUnderway: Bool, showsReadout: Bool = true) {
        sessionIsUnderway = isUnderway
        showsSessionReadout = isUnderway && showsReadout
        settle()
    }

    func sessionReadoutChanged(isShown: Bool) {
        showsSessionReadout = sessionIsUnderway && isShown
        if isShown == false { cursorIsOver = false }
        settle()
    }

    func reveal(_ task: Task.ID) {
        revealedTask = task
        state = .expanded
        layoutChanged?()
    }

    private func settle() {
        if plannerIsOpen {
            isAllotting = false
            state = .hidden
        } else if cursorIsOver || captureHasTheKeyboard || taskIsBeingDragged || isAllotting {
            state = .expanded
        } else {
            isAllotting = false
            state = showsSessionReadout ? .collapsed : .hidden
        }
        if state != .expanded { revealedTask = nil }
        layoutChanged?()
    }
}
