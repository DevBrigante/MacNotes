import AppKit
import Testing

@testable import MacNotes

/// The geometry tests prove what the metrics compute. This proves the window
/// actually obeys them — SwiftUI will happily resize a hosting view's window to
/// fit its content, and did.
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
