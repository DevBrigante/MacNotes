import Foundation
import Testing

@testable import MacNotes

private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo") ?? .gmt
    return calendar
}()

private func moment(_ year: Int, _ month: Int, _ day: Int, hour: Int) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))
        ?? .distantPast
}

struct DayTests {
    @Test func readsTheCalendarDateAndDropsTheTimeOfDay() {
        let firstThing = Day(moment(2026, 9, 3, hour: 0), in: calendar)
        let lastThing = Day(moment(2026, 9, 3, hour: 23), in: calendar)

        #expect(firstThing == lastThing)
        #expect(firstThing == Day(year: 2026, month: 9, day: 3))
    }

    @Test func ordersDaysChronologically() {
        #expect(Day(year: 2026, month: 9, day: 3) < Day(year: 2026, month: 9, day: 4))
        #expect(Day(year: 2026, month: 9, day: 30) < Day(year: 2026, month: 10, day: 1))
        #expect(Day(year: 2025, month: 12, day: 31) < Day(year: 2026, month: 1, day: 1))
    }

    @Test func writesItselfAsADateAnyoneCanRead() throws {
        let encoded = try JSONEncoder().encode([Day(year: 2026, month: 9, day: 3)])

        #expect(String(decoding: encoded, as: UTF8.self) == #"["2026-09-03"]"#)
    }

    @Test func readsBackEveryDayItWrote() throws {
        let days = [
            Day(year: 2026, month: 1, day: 5),
            Day(year: 1999, month: 12, day: 31),
            Day(year: 2026, month: 11, day: 30),
        ]

        let encoded = try JSONEncoder().encode(days)

        #expect(try JSONDecoder().decode([Day].self, from: encoded) == days)
    }

    @Test(arguments: [
        "2026-9-3", "2026/09/03", "03-09-2026", "", "tomorrow", "2026-09-03T10:00:00Z",
    ])
    func refusesTextThatIsNotACalendarDate(text: String) {
        let json = Data(#"["\#(text)"]"#.utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([Day].self, from: json)
        }
    }
}

struct DayMonthTests {
    @Test func stepsToTheFirstOfTheMonthEitherSide() {
        let september = Day(year: 2026, month: 9, day: 17)

        #expect(september.monthStepped(by: 1, in: calendar) == Day(year: 2026, month: 10, day: 1))
        #expect(september.monthStepped(by: -1, in: calendar) == Day(year: 2026, month: 8, day: 1))
    }

    @Test func stepsAcrossTheTurnOfTheYear() {
        #expect(
            Day(year: 2026, month: 12, day: 31).monthStepped(by: 1, in: calendar)
                == Day(year: 2027, month: 1, day: 1))
        #expect(
            Day(year: 2026, month: 1, day: 1).monthStepped(by: -1, in: calendar)
                == Day(year: 2025, month: 12, day: 1))
    }

    @Test func theLastOfALongMonthStillLandsOnAShortOnesFirst() {
        #expect(
            Day(year: 2026, month: 1, day: 31).monthStepped(by: 1, in: calendar)
                == Day(year: 2026, month: 2, day: 1))
    }

    @Test func standingStillIsTheFirstOfTheMonthItIsIn() {
        #expect(
            Day(year: 2026, month: 9, day: 17).monthStepped(by: 0, in: calendar)
                == Day(year: 2026, month: 9, day: 1))
    }

    @Test func stepsADayAtATimeOverTheEndOfAMonth() {
        #expect(
            Day(year: 2026, month: 9, day: 30).stepped(by: 1, in: calendar)
                == Day(year: 2026, month: 10, day: 1))
        #expect(
            Day(year: 2026, month: 1, day: 1).stepped(by: -1, in: calendar)
                == Day(year: 2025, month: 12, day: 31))
    }

    @Test func laysAMonthOutAsWholeWeeksStartingWhereItFalls() {
        let weeks = Day(year: 2026, month: 9, day: 17).itsMonthInWeeks(in: calendar)

        #expect(weeks.allSatisfy { $0.count == 7 })
        #expect(weeks.flatMap { $0 }.compactMap { $0 }.count == 30)
        #expect(weeks[0].compactMap { $0 }.first == Day(year: 2026, month: 9, day: 1))
    }

    @Test func theFirstOfTheMonthSitsUnderItsOwnWeekday() {
        var sunday = calendar
        sunday.firstWeekday = 1
        let weeks = Day(year: 2026, month: 9, day: 1).itsMonthInWeeks(in: sunday)
        let first = Day(year: 2026, month: 9, day: 1)

        #expect(weeks[0][first.placeInItsWeek(in: sunday)] == first)
        #expect(weeks[0].prefix(first.placeInItsWeek(in: sunday)).allSatisfy { $0 == nil })
    }
}
