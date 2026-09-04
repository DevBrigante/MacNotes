import Foundation
import Testing

@testable import MacNotes

struct CountdownTests {
    @Test(
        arguments: [
            (1500.0, "25:00"),
            (1499.5, "25:00"),
            (3600.0, "60:00"),
            (90.0, "1:30"),
            (59.4, "1:00"),
            (0.2, "0:01"),
            (0.0, "0:00"),
        ]
    )
    func readsTheTimeThatIsStillLeft(remaining: TimeInterval, text: String) {
        #expect(Countdown.text(remaining) == text)
    }

    @Test func aClockThatHasSomehowRunPastZeroStillReadsZero() {
        #expect(Countdown.text(-12) == "0:00")
    }
}
