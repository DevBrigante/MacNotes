import Foundation
import Testing

@testable import MacNotes

private let task = UUID()
private let anotherTask = UUID()

struct FocusSessionTests {
    private func started(
        _ allotted: AllottedTime = .init(minutes: 25),
        at now: TimeInterval = 0
    ) -> FocusSession {
        FocusSession(task: task, allotted: allotted, startedAt: now)
    }

    @Test func startsWithTheWholeAllottedTimeAhead() {
        let session = started(.init(minutes: 15))

        #expect(session.remaining(at: 0) == 15 * 60)
        #expect(session.hasEnded(at: 0) == false)
        #expect(session.isPaused == false)
    }

    @Test func countsDownAsTimePasses() {
        let session = started(.init(minutes: 25))

        #expect(session.remaining(at: 60) == 24 * 60)
        #expect(session.remaining(at: 20 * 60) == 5 * 60)
    }

    @Test func endsWhenTheAllottedTimeRunsOut() {
        let session = started(.init(minutes: 45))

        #expect(session.hasEnded(at: 45 * 60 - 1) == false)
        #expect(session.hasEnded(at: 45 * 60))
    }

    @Test func neverCountsPastZero() {
        let session = started(.init(minutes: 15))

        #expect(session.remaining(at: 15 * 60 + 3600) == 0)
    }

    @Test func aSessionStartedLaterCountsFromThatMoment() {
        let session = started(.init(minutes: 15), at: 1000)

        #expect(session.remaining(at: 1000) == 15 * 60)
        #expect(session.hasEnded(at: 999 + 15 * 60) == false)
        #expect(session.hasEnded(at: 1000 + 15 * 60))
    }

    @Test func pausingHoldsTheRemainingTimeStill() {
        var session = started(.init(minutes: 25))

        session.pause(at: 5 * 60)

        #expect(session.isPaused)
        #expect(session.remaining(at: 5 * 60) == 20 * 60)
        #expect(session.remaining(at: 5 * 60 + 3600) == 20 * 60)
    }

    @Test func resumingCarriesOnFromWhereItPaused() {
        var session = started(.init(minutes: 25))

        session.pause(at: 5 * 60)
        session.resume(at: 60 * 60)

        #expect(session.isPaused == false)
        #expect(session.remaining(at: 60 * 60) == 20 * 60)
        #expect(session.remaining(at: 60 * 60 + 60) == 19 * 60)
    }

    @Test func pausingAndResumingRepeatedlyNeitherLosesNorGainsTime() {
        var session = started(.init(minutes: 60))
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
        var session = started(.init(minutes: 15))

        session.pause(at: 60)
        session.pause(at: 600)

        #expect(session.remaining(at: 600) == 14 * 60)
    }

    @Test func resumingASessionThatWasNeverPausedChangesNothing() {
        var session = started(.init(minutes: 15))

        session.resume(at: 600)

        #expect(session.remaining(at: 600) == 5 * 60)
    }

    @Test func aPausedSessionNeverRunsOutOnItsOwn() {
        var session = started(.init(minutes: 15))

        session.pause(at: 60)

        #expect(session.hasEnded(at: 15 * 60 * 100) == false)
    }

    @Test func aSessionBelongsToOneTask() {
        #expect(started().task == task)
        #expect(
            FocusSession(task: anotherTask, allotted: .init(minutes: 15), startedAt: 0).task
                == anotherTask)
    }

    @Test func aSessionKeepsTheAllottedTimeItWasStartedWith() {
        #expect(started(.init(minutes: 45)).allotted == .init(minutes: 45))
    }
}
