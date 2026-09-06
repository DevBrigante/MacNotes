import SwiftUI

struct MonthCalendar: View {
    @Binding var month: Day
    let selected: Day?
    let today: Day
    let carries: (Day) -> Bool
    let pick: (Day) -> Void

    private let cell: CGFloat = 30
    private let gap: CGFloat = 1

    var body: some View {
        VStack(spacing: 6) {
            header
            headings
            grid
        }
    }

    private var header: some View {
        HStack(spacing: 0) {
            step("chevron.left", by: -1)
            Text(name)
                .font(.system(size: 12, weight: .semibold))
                .frame(maxWidth: .infinity)
            step("chevron.right", by: 1)
        }
    }

    private var name: String {
        guard let date = month.date() else { return "" }
        return date.formatted(.dateTime.month(.wide).year())
    }

    private func step(_ symbol: String, by steps: Int) -> some View {
        Button {
            month = month.monthStepped(by: steps)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }

    private var headings: some View {
        HStack(spacing: gap) {
            ForEach(Array(Self.weekdayHeadings().enumerated()), id: \.offset) { _, heading in
                Text(heading)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(width: cell)
            }
        }
    }

    private var grid: some View {
        VStack(spacing: gap) {
            ForEach(Array(month.itsMonthInWeeks().enumerated()), id: \.offset) { _, week in
                HStack(spacing: gap) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                        slot(day)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func slot(_ day: Day?) -> some View {
        if let day {
            Button {
                pick(day)
            } label: {
                face(day)
            }
            .buttonStyle(.plain)
        } else {
            Color.clear.frame(width: cell, height: cell)
        }
    }

    private func face(_ day: Day) -> some View {
        let chosen = day == selected
        return VStack(spacing: 2) {
            Text("\(day.day)")
                .font(.system(size: 12, weight: day == today ? .bold : .regular))
            Circle()
                .fill(carries(day) ? Color.primary.opacity(chosen ? 0.9 : 0.35) : .clear)
                .frame(width: 3, height: 3)
        }
        .foregroundStyle(chosen ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
        .frame(width: cell, height: cell)
        .background {
            if chosen {
                Circle().fill(Color.accentColor).frame(width: cell - 2, height: cell - 2)
            } else if day == today {
                Circle()
                    .strokeBorder(Color.accentColor, lineWidth: 1.5)
                    .frame(width: cell - 2, height: cell - 2)
            }
        }
        .contentShape(Rectangle())
    }

    static func weekdayHeadings(in calendar: Calendar = .current) -> [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        guard symbols.count == 7 else { return symbols }
        let first = calendar.firstWeekday - 1
        return (0..<7).map { symbols[(first + $0) % 7] }
    }
}
