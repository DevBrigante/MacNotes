import Foundation
import Testing

@testable import MacNotes

private let task = UUID()
private let anotherTask = UUID()

struct FocusSessionTests {
    private func started(
        _ duration: SessionDuration = .twentyFiveMinutes,
        at now: TimeInterval = 0
    ) -> FocusSession {
        FocusSession(task: task, duration: duration, startedAt: now)
    }

    @Test func startsWithTheWholeDurationAhead() {
        let session = started(.fifteenMinutes)

        #expect(session.remaining(at: 0) == 15 * 60)
        #expect(session.hasEnded(at: 0) == false)
        #expect(session.isPaused == false)
    }

    @Test func countsDownAsTimePasses() {
        let session = started(.twentyFiveMinutes)

        #expect(session.remaining(at: 60) == 24 * 60)
        #expect(session.remaining(at: 20 * 60) == 5 * 60)
    }

    @Test func endsWhenTheDurationRunsOut() {
        let session = started(.fortyFiveMinutes)

        #expect(session.hasEnded(at: 45 * 60 - 1) == false)
        #expect(session.hasEnded(at: 45 * 60))
    }

    @Test func neverCountsPastZero() {
        let session = started(.fifteenMinutes)

        #expect(session.remaining(at: 15 * 60 + 3600) == 0)
    }

    @Test func aSessionStartedLaterCountsFromThatMoment() {
        let session = started(.fifteenMinutes, at: 1000)

        #expect(session.remaining(at: 1000) == 15 * 60)
        #expect(session.hasEnded(at: 999 + 15 * 60) == false)
        #expect(session.hasEnded(at: 1000 + 15 * 60))
    }

    @Test func pausingHoldsTheRemainingTimeStill() {
        var session = started(.twentyFiveMinutes)

        session.pause(at: 5 * 60)

        #expect(session.isPaused)
        #expect(session.remaining(at: 5 * 60) == 20 * 60)
        #expect(session.remaining(at: 5 * 60 + 3600) == 20 * 60)
    }

    @Test func resumingCarriesOnFromWhereItPaused() {
        var session = started(.twentyFiveMinutes)

        session.pause(at: 5 * 60)
        session.resume(at: 60 * 60)

        #expect(session.isPaused == false)
        #expect(session.remaining(at: 60 * 60) == 20 * 60)
        #expect(session.remaining(at: 60 * 60 + 60) == 19 * 60)
    }

    @Test func pausingAndResumingRepeatedlyNeitherLosesNorGainsTime() {
        var session = started(.sixtyMinutes)
        var now: TimeInterval = 0

        for _ in 0..<10 {
            now += 30
            session.pause(at: now)
            now += 300
            session.resume(at: now)
        }
        now += 30

        #expect(session.remaining(at: now) == 60 * 60 - 11 * 30)
    }

    @Test func pausingAnAlreadyPausedSessionChangesNothing() {
        var session = started(.fifteenMinutes)

        session.pause(at: 60)
        session.pause(at: 600)

        #expect(session.remaining(at: 600) == 14 * 60)
    }

    @Test func resumingASessionThatWasNeverPausedChangesNothing() {
        var session = started(.fifteenMinutes)

        session.resume(at: 600)

        #expect(session.remaining(at: 600) == 5 * 60)
    }

    @Test func aPausedSessionNeverRunsOutOnItsOwn() {
        var session = started(.fifteenMinutes)

        session.pause(at: 60)

        #expect(session.hasEnded(at: 15 * 60 * 100) == false)
    }

    @Test func aSessionBelongsToOneTask() {
        #expect(started().task == task)
        #expect(
            FocusSession(task: anotherTask, duration: .fifteenMinutes, startedAt: 0).task
                == anotherTask)
    }

    @Test func aSessionKeepsTheDurationItWasStartedWith() {
        #expect(started(.fortyFiveMinutes).duration == .fortyFiveMinutes)
    }
}
