import AppKit
import Testing

@testable import MacNotes

@MainActor
struct NotchWindowControllerTests {
    @Test func theWindowTakesTheFrameTheMetricsAskFor() {
        let controller = NotchWindowController()

        #expect(controller.panel.frame == controller.intendedFrame)
    }

    @Test func theWindowSitsAboveTheMenuBar() {
        let controller = NotchWindowController()

        #expect(controller.panel.level.rawValue > Int(CGWindowLevelForKey(.mainMenuWindow)))
    }
}
