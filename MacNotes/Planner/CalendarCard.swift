import SwiftUI

struct CalendarCard: View {
    let access: CalendarAccess
    let events: [CalendarEvent]
    let connect: () -> Void
    let openSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Calendar")
                .font(.system(size: 13, weight: .semibold))

            switch access {
            case .notConnected:
                connection
            case .connected:
                schedule
            case .denied:
                denied
            }
        }
        .padding(12)
    }

    private var connection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MacNotes reads Calendar events and never writes them.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Button("Connect Calendar", action: connect)
                .controlSize(.small)
        }
    }

    @ViewBuilder
    private var schedule: some View {
        if events.isEmpty {
            Text("No events this day")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        } else {
            ForEach(events) { event in
                HStack(spacing: 8) {
                    Text(event.title)
                        .font(.system(size: 12))
                    Spacer(minLength: 0)
                    Text(time(for: event))
                        .font(.system(size: 11).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var denied: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Allow Calendar access in System Settings to see events here.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Button("Open System Settings", action: openSettings)
                .controlSize(.small)
        }
    }

    private func time(for event: CalendarEvent) -> String {
        guard event.isAllDay == false else { return "All-day" }
        return "\(event.startsAt.formatted(date: .omitted, time: .shortened))–\(event.endsAt.formatted(date: .omitted, time: .shortened))"
    }
}
