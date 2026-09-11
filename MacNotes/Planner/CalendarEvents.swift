import AppKit
import EventKit
import Foundation
import Observation

enum CalendarAccess: Equatable {
    case notConnected
    case connected
    case denied
    case unavailable
}

struct CalendarEvent: Equatable, Identifiable {
    let id: String
    let title: String
    let startsAt: Date
    let endsAt: Date
    let isAllDay: Bool
}

@MainActor
protocol CalendarEventSource: AnyObject {
    var access: CalendarAccess { get }

    func requestAccess() async throws
    func events(on day: Day) -> [CalendarEvent]
    func openSettings()
}

@MainActor
@Observable
final class CalendarEvents {
    private(set) var access: CalendarAccess
    private(set) var events: [CalendarEvent] = []

    @ObservationIgnored private let source: any CalendarEventSource
    @ObservationIgnored private var day: Day?

    init(source: any CalendarEventSource) {
        self.source = source
        access = source.access
    }

    convenience init() {
        self.init(source: EventKitCalendarEventSource())
    }

    func load(on day: Day) {
        self.day = day
        access = source.access
        refresh()
    }

    func connect() async {
        do {
            try await source.requestAccess()
            access = source.access
        } catch {
            access = .unavailable
        }
        refresh()
    }

    func openSettings() {
        source.openSettings()
    }

    private func refresh() {
        guard access == .connected, let day else {
            events = []
            return
        }
        events = source.events(on: day)
    }
}

@MainActor
private final class EventKitCalendarEventSource: CalendarEventSource {
    private let store = EKEventStore()

    var access: CalendarAccess {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess, .authorized:
            .connected
        case .notDetermined:
            .notConnected
        case .denied, .restricted, .writeOnly:
            .denied
        @unknown default:
            .denied
        }
    }

    func requestAccess() async throws {
        NSApp.activate(ignoringOtherApps: true)
        _ = try await store.requestFullAccessToEvents()
    }

    func events(on day: Day) -> [CalendarEvent] {
        guard let start = day.date(),
            let end = Calendar.current.date(byAdding: .day, value: 1, to: start)
        else { return [] }

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
            .map { event in
                let id = event.eventIdentifier ?? event.calendarItemIdentifier
                return CalendarEvent(
                    id: id,
                    title: event.title ?? "Untitled Event",
                    startsAt: event.startDate,
                    endsAt: event.endDate,
                    isAllDay: event.isAllDay)
            }
    }

    func openSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")
        else { return }
        NSWorkspace.shared.open(url)
    }
}
