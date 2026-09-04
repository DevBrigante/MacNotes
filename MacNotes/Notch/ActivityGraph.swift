import AppKit
import SwiftUI

struct ActivityGraph: View {
    static let ceiling = 4
    static let width: CGFloat = 147

    let tasks: TaskStore
    let month: Day

    @State private var accent = SystemAccent.colour()

    private let cell: CGFloat = 15
    private let gap: CGFloat = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            heading
            grid
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .frame(width: Self.width, alignment: .leading)
        .onReceive(
            NotificationCenter.default.publisher(for: NSColor.systemColorsDidChangeNotification)
        ) { _ in
            accent = SystemAccent.colour()
        }
    }

    private var heading: some View {
        HStack(spacing: 4) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 8, weight: .semibold))
            Text("Activity")
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(Color.white.opacity(0.6))
    }

    private var grid: some View {
        VStack(alignment: .leading, spacing: gap) {
            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: gap) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(fill(day))
                            .frame(width: cell, height: cell)
                    }
                }
            }
        }
    }

    private var weeks: [[Day?]] {
        let days = month.itsMonth()
        guard let first = days.first else { return [] }

        var slots: [Day?] = Array(repeating: nil, count: first.placeInItsWeek())
        slots.append(contentsOf: days.map { Optional($0) })
        while slots.count % 7 != 0 {
            slots.append(nil)
        }
        return stride(from: 0, to: slots.count, by: 7).map { Array(slots[$0..<$0 + 7]) }
    }

    private func fill(_ day: Day?) -> Color {
        guard let day else { return .clear }
        let done = tasks.completions(on: day)
        guard done > 0 else { return Color.white.opacity(0.07) }
        let share = min(Double(done) / Double(Self.ceiling), 1)
        return accent.opacity(0.3 + 0.7 * share)
    }
}
