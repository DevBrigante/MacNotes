import Testing

@testable import MacNotes

@MainActor
struct NotchPanelModelTests {
    @Test func restsHiddenUntilTheCursorArrives() {
        let model = NotchPanelModel()

        #expect(model.state == .hidden)
    }

    @Test func theCursorExpandsThePanel() {
        let model = NotchPanelModel()

        model.cursorMoved(isOver: true)

        #expect(model.state == .expanded)
    }

    @Test func theCursorLeavingHidesItAgain() {
        let model = NotchPanelModel()

        model.cursorMoved(isOver: true)
        model.cursorMoved(isOver: false)

        #expect(model.state == .hidden)
    }

    @Test func theCursorCanComeAndGoRepeatedly() {
        let model = NotchPanelModel()

        for _ in 0..<3 {
            model.cursorMoved(isOver: true)
            #expect(model.state == .expanded)

            model.cursorMoved(isOver: false)
            #expect(model.state == .hidden)
        }
    }

    @Test func aSessionUnderwayCollapsesThePanel() {
        let model = NotchPanelModel()

        model.sessionChanged(isUnderway: true)

        #expect(model.state == .collapsed)
    }

    @Test func theCursorStillExpandsThePanelOverASession() {
        let model = NotchPanelModel()
        model.sessionChanged(isUnderway: true)

        model.cursorMoved(isOver: true)

        #expect(model.state == .expanded)
    }

    @Test func theCursorLeavingASessionCollapsesRatherThanHides() {
        let model = NotchPanelModel()
        model.sessionChanged(isUnderway: true)
        model.cursorMoved(isOver: true)

        model.cursorMoved(isOver: false)

        #expect(model.state == .collapsed)
    }

    @Test func theSessionEndingHidesThePanelTheCursorIsAwayFrom() {
        let model = NotchPanelModel()
        model.sessionChanged(isUnderway: true)

        model.sessionChanged(isUnderway: false)

        #expect(model.state == .hidden)
    }

    @Test func theSessionEndingUnderTheCursorLeavesThePanelExpanded() {
        let model = NotchPanelModel()
        model.cursorMoved(isOver: true)
        model.sessionChanged(isUnderway: true)

        model.sessionChanged(isUnderway: false)

        #expect(model.state == .expanded)
    }

    @Test func aSessionStartingUnderTheCursorLeavesThePanelExpanded() {
        let model = NotchPanelModel()
        model.cursorMoved(isOver: true)

        model.sessionChanged(isUnderway: true)

        #expect(model.state == .expanded)
    }

    @Test func quickCaptureHoldsThePanelOpenWhenTheCursorLeaves() {
        let model = NotchPanelModel()
        model.cursorMoved(isOver: true)
        model.captureChanged(hasTheKeyboard: true)

        model.cursorMoved(isOver: false)

        #expect(model.state == .expanded)
    }

    @Test func lettingTheKeyboardGoSettlesThePanelAgain() {
        let model = NotchPanelModel()
        model.cursorMoved(isOver: true)
        model.captureChanged(hasTheKeyboard: true)
        model.cursorMoved(isOver: false)

        model.captureChanged(hasTheKeyboard: false)

        #expect(model.state == .hidden)
    }

    @Test func lettingTheKeyboardGoOverASessionCollapsesRatherThanHides() {
        let model = NotchPanelModel()
        model.sessionChanged(isUnderway: true)
        model.cursorMoved(isOver: true)
        model.captureChanged(hasTheKeyboard: true)
        model.cursorMoved(isOver: false)

        model.captureChanged(hasTheKeyboard: false)

        #expect(model.state == .collapsed)
    }

    @Test func aTaskBeingDraggedHoldsThePanelOpenWhenTheCursorLeaves() {
        let model = NotchPanelModel()
        model.cursorMoved(isOver: true)
        model.dragChanged(isDragging: true)

        model.cursorMoved(isOver: false)

        #expect(model.state == .expanded)

        model.dragChanged(isDragging: false)

        #expect(model.state == .hidden)
    }

    @Test func anAllottedTimeBeingSetHoldsThePanelOpenWhenTheCursorLeaves() {
        let model = NotchPanelModel()
        model.cursorMoved(isOver: true)
        model.allottingChanged(isAllotting: true)

        model.cursorMoved(isOver: false)

        #expect(model.state == .expanded)
        #expect(model.isAllotting)

        model.allottingChanged(isAllotting: false)

        #expect(model.state == .hidden)
    }

    @Test func thePlannerOpeningHidesThePanelTheCursorIsSittingOn() {
        let model = NotchPanelModel()
        model.cursorMoved(isOver: true)

        model.plannerChanged(isOpen: true)

        #expect(model.state == .hidden)
    }

    @Test func thePlannerOpeningHidesThePanelOverARunningSession() {
        let model = NotchPanelModel()
        model.sessionChanged(isUnderway: true)

        model.plannerChanged(isOpen: true)

        #expect(model.state == .hidden)
    }

    @Test func thePlannerOpeningForgetsThatAnAllottedTimeWasBeingSet() {
        let model = NotchPanelModel()
        model.cursorMoved(isOver: true)
        model.allottingChanged(isAllotting: true)

        model.plannerChanged(isOpen: true)

        #expect(model.isAllotting == false)
        #expect(model.state == .hidden)
    }

    @Test func thePlannerClosingGivesTheSessionItsStripBack() {
        let model = NotchPanelModel()
        model.sessionChanged(isUnderway: true)
        model.plannerChanged(isOpen: true)

        model.plannerChanged(isOpen: false)

        #expect(model.state == .collapsed)
    }

    @Test func thePlannerClosingLeavesTheCursorWhereItWas() {
        let model = NotchPanelModel()
        model.cursorMoved(isOver: true)
        model.plannerChanged(isOpen: true)
        model.cursorMoved(isOver: false)

        model.plannerChanged(isOpen: false)

        #expect(model.state == .hidden)
    }

    @Test func askingForThePlannerReachesWhoeverOpensIt() {
        let model = NotchPanelModel()
        var asked = 0
        model.plannerAsked = { asked += 1 }

        model.askForThePlanner()

        #expect(asked == 1)
    }

    @Test func thePanelClosingForgetsThatAnAllottedTimeWasBeingSet() {
        let model = NotchPanelModel()
        model.cursorMoved(isOver: true)
        model.allottingChanged(isAllotting: true)
        model.allottingChanged(isAllotting: false)

        model.cursorMoved(isOver: false)

        #expect(model.isAllotting == false)
        #expect(model.state == .hidden)
    }
}
