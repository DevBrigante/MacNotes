import Foundation

nonisolated struct Day: Codable, Comparable, Hashable, Sendable {
    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    init(_ date: Date, in calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year ?? 0, month: parts.month ?? 0, day: parts.day ?? 0)
    }

    static func today(in calendar: Calendar = .current) -> Day {
        Day(Date(), in: calendar)
    }

    var text: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    init?(text: String) {
        let parts = text.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
            let year = Self.number(parts[0], digits: 4),
            let month = Self.number(parts[1], digits: 2),
            let day = Self.number(parts[2], digits: 2)
        else { return nil }

        self.init(year: year, month: month, day: day)
    }

    private static func number(_ text: Substring, digits: Int) -> Int? {
        guard text.count == digits, text.allSatisfy({ $0.isASCII && $0.isNumber }) else {
            return nil
        }
        return Int(text)
    }

    static func < (left: Day, right: Day) -> Bool {
        (left.year, left.month, left.day) < (right.year, right.month, right.day)
    }

    init(from decoder: any Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        guard let day = Day(text: text) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "\(text) is not a calendar date of the form 2026-09-03"
                )
            )
        }
        self = day
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(text)
    }
}

extension Day {
    func date(in calendar: Calendar = .current) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    func itsMonth(in calendar: Calendar = .current) -> [Day] {
        guard let date = date(in: calendar),
            let range = calendar.range(of: .day, in: .month, for: date)
        else { return [self] }
        return range.map { Day(year: year, month: month, day: $0) }
    }

    func itsMonthInWeeks(in calendar: Calendar = .current) -> [[Day?]] {
        let days = itsMonth(in: calendar)
        guard let first = days.first else { return [] }

        var slots: [Day?] = Array(repeating: nil, count: first.placeInItsWeek(in: calendar))
        slots.append(contentsOf: days.map { Optional($0) })
        while slots.count % 7 != 0 {
            slots.append(nil)
        }
        return stride(from: 0, to: slots.count, by: 7).map { Array(slots[$0..<$0 + 7]) }
    }

    func stepped(by days: Int, in calendar: Calendar = .current) -> Day {
        guard let date = date(in: calendar),
            let stepped = calendar.date(byAdding: .day, value: days, to: date)
        else { return self }
        return Day(stepped, in: calendar)
    }

    var firstOfItsMonth: Day {
        Day(year: year, month: month, day: 1)
    }

    func monthStepped(by steps: Int, in calendar: Calendar = .current) -> Day {
        guard let start = firstOfItsMonth.date(in: calendar),
            let stepped = calendar.date(byAdding: .month, value: steps, to: start)
        else { return firstOfItsMonth }
        return Day(stepped, in: calendar)
    }

    func placeInItsWeek(in calendar: Calendar = .current) -> Int {
        guard let date = date(in: calendar) else { return 0 }
        let weekday = calendar.component(.weekday, from: date)
        return (weekday - calendar.firstWeekday + 7) % 7
    }
}
