import Foundation
import Testing

@testable import MacNotes

@MainActor
final class CalendarEventsTests {
    private let day = Day(year: 2026, month: 9, day: 4)

    @Test func aConnectedCalendarShowsOnlyTheEventsForTheRequestedDay() {
        let morning = CalendarEvent(
            id: "morning", title: "Team standup",
            startsAt: Date(timeIntervalSince1970: 1_788_519_200),
            endsAt: Date(timeIntervalSince1970: 1_788_520_100), isAllDay: false)
        let source = CalendarEventSourceStub(access: .connected, events: [morning])
        let calendar = CalendarEvents(source: source)

        calendar.load(on: day)

        #expect(calendar.events == [morning])
        #expect(source.requestedDays == [day])
    }

    @Test func aCalendarWithoutAccessDoesNotReadEvents() {
        let source = CalendarEventSourceStub(access: .notConnected)
        let calendar = CalendarEvents(source: source)

        calendar.load(on: day)

        #expect(calendar.events.isEmpty)
        #expect(source.requestedDays.isEmpty)
    }

    @Test func connectingRequestsFullAccessAndLoadsTheCurrentDay() async {
        let event = CalendarEvent(
            id: "lunch", title: "Lunch",
            startsAt: Date(timeIntervalSince1970: 1_788_533_600),
            endsAt: Date(timeIntervalSince1970: 1_788_537_200), isAllDay: false)
        let source = CalendarEventSourceStub(access: .notConnected, events: [event])
        let calendar = CalendarEvents(source: source)

        calendar.load(on: day)
        await calendar.connect()

        #expect(source.didRequestAccess)
        #expect(calendar.access == .connected)
        #expect(calendar.events == [event])
        #expect(source.requestedDays == [day])
    }

    @Test func aDeniedCalendarOffersSystemSettingsWithoutReadingEvents() {
        let source = CalendarEventSourceStub(access: .denied)
        let calendar = CalendarEvents(source: source)

        calendar.load(on: day)
        calendar.openSettings()

        #expect(calendar.events.isEmpty)
        #expect(source.didOpenSettings)
    }
}

@MainActor
final class CalendarEventSourceStub: CalendarEventSource {
    var access: CalendarAccess
    var events: [CalendarEvent]
    private(set) var requestedDays: [Day] = []
    private(set) var didRequestAccess = false
    private(set) var didOpenSettings = false

    init(access: CalendarAccess, events: [CalendarEvent] = []) {
        self.access = access
        self.events = events
    }

    func requestAccess() async throws {
        didRequestAccess = true
        access = .connected
    }

    func events(on day: Day) -> [CalendarEvent] {
        requestedDays.append(day)
        return events
    }

    func openSettings() {
        didOpenSettings = true
    }
}
