import AppKit
import Testing

@testable import MacNotes

@MainActor
final class NotchWindowControllerTests {
    private let folder = TemporaryFolder()

    deinit {
        folder.discard()
    }

    private func controller() -> NotchWindowController {
        NotchWindowController(
            tasks: TaskStore(file: JSONFile(name: "tasks.json", in: folder.url), saveDelay: 60))
    }

    @Test func theWindowTakesTheFrameTheMetricsAskFor() {
        let controller = controller()

        #expect(controller.panel.frame == controller.intendedFrame)
    }

    @Test func theWindowSitsAboveTheMenuBar() {
        let controller = controller()

        #expect(controller.panel.level.rawValue > Int(CGWindowLevelForKey(.mainMenuWindow)))
    }

    @Test func aSessionUnderwayCollapsesTheWindowOntoItsStrip() {
        let controller = controller()
        let hidden = controller.intendedFrame

        controller.sessions.start(.init(minutes: 25), on: UUID())

        #expect(controller.intendedFrame.width > hidden.width)
    }

    @Test func theWindowGivesTheStripBackWhenTheSessionEnds() {
        let controller = controller()
        let hidden = controller.intendedFrame

        controller.sessions.start(.init(minutes: 25), on: UUID())
        controller.sessions.end()

        #expect(controller.intendedFrame == hidden)
    }

    @Test func theWindowFollowsThePanelOntoTheCollapsedFrame() {
        let controller = controller()

        controller.sessions.start(.init(minutes: 25), on: UUID())
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))

        #expect(controller.panel.frame == controller.intendedFrame)
    }

    @Test func theWindowLandsOnTheDisplayUnderTheCursor() throws {
        let controller = controller()
        let screen = try #require(NSScreen.underTheCursor ?? NSScreen.main)

        #expect(screen.frame.intersects(controller.panel.frame))
        #expect(controller.panel.frame.maxY == screen.frame.maxY)
    }

    @Test func theWindowCanTakeTheKeyboardForQuickCapture() {
        let controller = controller()

        #expect(controller.panel.canBecomeKey)
        #expect(controller.panel.styleMask.contains(.nonactivatingPanel))
    }
}
