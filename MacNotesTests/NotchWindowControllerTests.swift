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

    @Test func aSessionUnderwayCollapsesTheWindowOntoItsStrip() {
        let controller = NotchWindowController()
        let hidden = controller.intendedFrame

        controller.sessions.start(.twentyFiveMinutes, on: UUID())

        #expect(controller.intendedFrame.width > hidden.width)
    }

    @Test func theWindowGivesTheStripBackWhenTheSessionEnds() {
        let controller = NotchWindowController()
        let hidden = controller.intendedFrame

        controller.sessions.start(.twentyFiveMinutes, on: UUID())
        controller.sessions.end()

        #expect(controller.intendedFrame == hidden)
    }

    @Test func theWindowFollowsThePanelOntoTheCollapsedFrame() {
        let controller = NotchWindowController()

        controller.sessions.start(.twentyFiveMinutes, on: UUID())
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))

        #expect(controller.panel.frame == controller.intendedFrame)
    }

    @Test func theWindowLandsOnTheDisplayUnderTheCursor() throws {
        let controller = NotchWindowController()
        let screen = try #require(NSScreen.underTheCursor ?? NSScreen.main)

        #expect(screen.frame.intersects(controller.panel.frame))
        #expect(controller.panel.frame.maxY == screen.frame.maxY)
    }
}
