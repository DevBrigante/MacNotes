import AppKit
import Foundation
import Testing

@testable import MacNotes

@MainActor
final class PlannerWindowControllerTests {
    private let folder = TemporaryFolder()
    private let controller: PlannerWindowController
    private var ordinary: [Bool] = []

    init() {
        controller = PlannerWindowController(
            tasks: TaskStore(file: JSONFile(name: "tasks.json", in: folder.url), saveDelay: 60),
            sessions: FocusSessionModel(now: { 0 }, tick: 60, workspace: NotificationCenter()))
        controller.appBecomesOrdinary = { [weak self] in self?.ordinary.append($0) }
    }

    deinit {
        folder.discard()
    }

    @Test func theWindowIsOneTheUserCanClosePutAsideAndResize() {
        #expect(controller.window.styleMask.contains(.titled))
        #expect(controller.window.styleMask.contains(.closable))
        #expect(controller.window.styleMask.contains(.miniaturizable))
        #expect(controller.window.styleMask.contains(.resizable))
        #expect(controller.window.isReleasedWhenClosed == false)
    }

    @Test func theWindowRestsClosedUntilThePanelAsksForIt() {
        #expect(controller.isOpen == false)
    }

    @Test func openingSaysSoAndTakesTheAppOutOfItsAccessoryRole() {
        var opened: [Bool] = []
        controller.openChanged = { opened.append($0) }

        controller.open()

        #expect(controller.isOpen)
        #expect(opened == [true])
        #expect(ordinary == [true])

        controller.close()
    }

    @Test func closingSaysSoAndGivesTheAppItsAccessoryRoleBack() {
        var opened: [Bool] = []
        controller.open()
        controller.openChanged = { opened.append($0) }

        controller.close()

        #expect(controller.isOpen == false)
        #expect(opened == [false])
        #expect(ordinary == [true, false])
    }

    @Test func closingAWindowThatIsNotThereChangesNothing() {
        var opened: [Bool] = []
        controller.openChanged = { opened.append($0) }

        controller.close()

        #expect(opened.isEmpty)
        #expect(ordinary.isEmpty)
    }

    @Test func openingOnADisplayCentresThePlannerInItsVisibleArea() {
        let window = NSRect(x: 0, y: 0, width: 780, height: 500)
        let display = NSRect(x: 1512, y: 24, width: 2560, height: 1416)

        let frame = PlannerWindowController.frame(window, centredIn: display)

        #expect(frame.midX == display.midX)
        #expect(frame.midY == display.midY)
        #expect(frame.size == window.size)
    }

    @Test func becomingKeyRefreshesCalendarAccessAfterSystemSettings() {
        let event = CalendarEvent(
            id: "review", title: "Design review",
            startsAt: Date(timeIntervalSince1970: 1_788_608_400),
            endsAt: Date(timeIntervalSince1970: 1_788_612_000), isAllDay: false)
        let source = CalendarEventSourceStub(access: .denied, events: [event])
        let calendar = CalendarEvents(source: source)
        let controller = PlannerWindowController(
            tasks: TaskStore(file: JSONFile(name: "tasks.json", in: folder.url), saveDelay: 60),
            sessions: FocusSessionModel(now: { 0 }, tick: 60, workspace: NotificationCenter()),
            calendar: calendar)

        source.access = .connected
        controller.windowDidBecomeKey(Notification(name: NSWindow.didBecomeKeyNotification))

        #expect(calendar.events == [event])
    }
}

struct MonthCalendarTests {
    private func gregorian(firstWeekday: Int) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    @Test func theHeadingsStartOnTheDayTheUsersCalendarStartsOn() {
        #expect(
            MonthCalendar.weekdayHeadings(in: gregorian(firstWeekday: 1))
                == ["S", "M", "T", "W", "T", "F", "S"])
        #expect(
            MonthCalendar.weekdayHeadings(in: gregorian(firstWeekday: 2))
                == ["M", "T", "W", "T", "F", "S", "S"])
    }

    @Test func theDayChipNamesTheDaysAroundTodayAndDatesTheRest() {
        let calendar = gregorian(firstWeekday: 1)
        let today = Day(year: 2026, month: 9, day: 4)

        #expect(PlannerCard.dayLabel(for: nil, on: today, in: calendar) == "No Day")
        #expect(PlannerCard.dayLabel(for: today, on: today, in: calendar) == "Today")
        #expect(
            PlannerCard.dayLabel(for: Day(year: 2026, month: 9, day: 5), on: today, in: calendar)
                == "Tomorrow")
        #expect(
            PlannerCard.dayLabel(for: Day(year: 2026, month: 9, day: 3), on: today, in: calendar)
                == "Yesterday")
        #expect(
            PlannerCard.dayLabel(for: Day(year: 2026, month: 12, day: 24), on: today, in: calendar)
                .isEmpty == false)
    }
}
