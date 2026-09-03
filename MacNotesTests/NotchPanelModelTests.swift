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
}
