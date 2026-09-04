import Foundation
import Testing

@testable import MacNotes

struct SessionDurationTests {
    @Test func offersTheFixedPresets() {
        #expect(SessionDuration.allCases.map(\.minutes) == [15, 25, 45, 60])
    }

    @Test func aDurationIsItsMinutesInSeconds() {
        #expect(SessionDuration.twentyFiveMinutes.seconds == 25 * 60)
        #expect(SessionDuration.sixtyMinutes.seconds == 60 * 60)
    }
}
