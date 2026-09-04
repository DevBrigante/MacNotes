import Foundation
import Testing

@testable import MacNotes

struct AllottedTimeTests {
    @Test func offersThePresetsTheCardShows() {
        #expect(AllottedTime.presets == [10, 15, 25, 30, 45, 60])
    }

    @Test func isItsMinutesInSeconds() {
        #expect(AllottedTime(minutes: 25).seconds == 25 * 60)
        #expect(AllottedTime(minutes: 1).seconds == 60)
    }

    @Test func stepsOneMinuteAtATime() {
        #expect(AllottedTime(minutes: 25).stepped(by: 1).minutes == 26)
        #expect(AllottedTime(minutes: 25).stepped(by: -1).minutes == 24)
    }

    @Test func neverLeavesTheFloorOrTheCeiling() {
        #expect(AllottedTime(minutes: 0).minutes == 1)
        #expect(AllottedTime(minutes: -30).minutes == 1)
        #expect(AllottedTime(minutes: 61).minutes == 60)
        #expect(AllottedTime(minutes: 1).stepped(by: -1).minutes == 1)
        #expect(AllottedTime(minutes: 60).stepped(by: 1).minutes == 60)
    }

    @Test func isWrittenDownAsPlainMinutes() throws {
        let encoded = try JSONEncoder().encode(AllottedTime(minutes: 45))

        #expect(String(decoding: encoded, as: UTF8.self) == "45")
        #expect(try JSONDecoder().decode(AllottedTime.self, from: encoded).minutes == 45)
    }

    @Test func aStoredTimeOutsideTheRangeIsBroughtBackIn() throws {
        let encoded = Data("900".utf8)

        #expect(try JSONDecoder().decode(AllottedTime.self, from: encoded).minutes == 60)
    }
}
