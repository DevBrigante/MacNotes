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
            tasks: TaskStore(file: JSONFile(name: "tasks.json", in: folder.url), saveDelay: 60),
            sessions: FocusSessionModel(),
            settings: SettingsStore(file: JSONFile(name: "settings.json", in: folder.url)))
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

    @Test func aLongSessionGetsTheWiderCollapsedFrame() {
        let controller = controller()

        controller.sessions.start(.init(minutes: 9), on: UUID())
        let compact = controller.intendedFrame
        controller.sessions.start(.init(minutes: 30), on: UUID())
        let wide = controller.intendedFrame

        #expect(wide.width > compact.width)
    }

    @Test func theWindowGivesTheStripBackWhenTheSessionEnds() {
        let controller = controller()
        let hidden = controller.intendedFrame

        controller.sessions.start(.init(minutes: 25), on: UUID())
        controller.sessions.end()

        #expect(controller.intendedFrame == hidden)
    }

    @Test func aPausedSessionHidesItsReadoutAfterTheConfiguredDelay() {
        let sessions = FocusSessionModel()
        let controller = NotchWindowController(
            tasks: TaskStore(file: JSONFile(name: "tasks.json", in: folder.url), saveDelay: 60),
            sessions: sessions,
            settings: SettingsStore(file: JSONFile(name: "settings.json", in: folder.url)),
            pausedSessionReadoutDelay: 0.01)

        sessions.start(.init(minutes: 25), on: UUID())
        sessions.pause()
        let remainingAtPause = sessions.remaining
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        #expect(controller.model.state == .hidden)

        controller.model.cursorMoved(isOver: true)

        #expect(controller.model.state == .expanded)
        #expect(sessions.session?.isPaused == true)
        #expect(sessions.remaining == remainingAtPause)
    }

    @Test func hidingReadoutsResizesTheCollapsedPanelImmediately() {
        let sessions = FocusSessionModel()
        let settings = SettingsStore(file: JSONFile(name: "settings.json", in: folder.url))
        let controller = NotchWindowController(
            tasks: TaskStore(file: JSONFile(name: "tasks.json", in: folder.url), saveDelay: 60),
            sessions: sessions,
            settings: settings)

        sessions.start(.init(minutes: 25), on: UUID())
        let full = controller.intendedFrame

        settings.setTaskTitleShown(false)
        let timerOnly = controller.intendedFrame

        settings.setTimerShown(false)
        let empty = controller.intendedFrame

        #expect(timerOnly.width < full.width)
        #expect(empty.width < timerOnly.width)
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
