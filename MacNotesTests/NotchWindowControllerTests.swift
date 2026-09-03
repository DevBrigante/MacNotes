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

    @Test func theWindowLandsOnTheDisplayUnderTheCursor() throws {
        let controller = NotchWindowController()
        let screen = try #require(NSScreen.underTheCursor ?? NSScreen.main)

        #expect(screen.frame.intersects(controller.panel.frame))
        #expect(controller.panel.frame.maxY == screen.frame.maxY)
    }
}
