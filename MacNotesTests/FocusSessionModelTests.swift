import Foundation
import Testing

@testable import MacNotes

private let task = UUID()
private let anotherTask = UUID()
private let tick: TimeInterval = 0.05

@MainActor
final class FocusSessionModelTests {
    private let stopwatch = Stopwatch()
    private let sessions: FocusSessionModel

    init() {
        let stopwatch = self.stopwatch
        sessions = FocusSessionModel(now: { stopwatch.now }, tick: tick)
    }

    private func letTheClockRun() {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: tick * 4))
    }

    @Test func restsWithNoSessionUntilOneIsStarted() {
        #expect(sessions.session == nil)
        #expect(sessions.isRunning == false)
        #expect(sessions.remaining == 0)
        #expect(sessions.clock == nil)
    }

    @Test func startingASessionRunsItAgainstItsTask() {
        sessions.start(.twentyFiveMinutes, on: task)

        #expect(sessions.session?.task == task)
        #expect(sessions.isRunning)
        #expect(sessions.remaining == 25 * 60)
        #expect(sessions.clock != nil)
    }

    @Test func theRemainingTimeFollowsTheClock() {
        sessions.start(.twentyFiveMinutes, on: task)

        stopwatch.advance(by: 60)
        letTheClockRun()

        #expect(sessions.remaining == 24 * 60)
    }

    @Test func startingOnAnotherTaskLeavesNoTraceOfThePreviousSession() {
        sessions.start(.twentyFiveMinutes, on: task)
        stopwatch.advance(by: 5 * 60)

        sessions.start(.fifteenMinutes, on: anotherTask)

        #expect(sessions.session?.task == anotherTask)
        #expect(sessions.remaining == 15 * 60)
    }

    @Test func switchingLeavesNoSecondClockBehind() {
        sessions.start(.twentyFiveMinutes, on: task)
        let clock = sessions.clock

        sessions.start(.fifteenMinutes, on: anotherTask)

        #expect(sessions.clock === clock)
    }

    @Test func aSessionSwitchedAwayFromNeverRunsOutLater() {
        sessions.start(.fifteenMinutes, on: task)
        sessions.start(.sixtyMinutes, on: anotherTask)

        stopwatch.advance(by: 15 * 60)
        letTheClockRun()

        #expect(sessions.session?.task == anotherTask)
        #expect(sessions.remaining == 45 * 60)
    }

    @Test func pausingHoldsTheTimeStillAndPutsTheClockDown() {
        sessions.start(.twentyFiveMinutes, on: task)
        stopwatch.advance(by: 60)

        sessions.pause()
        stopwatch.advance(by: 10 * 60)
        letTheClockRun()

        #expect(sessions.remaining == 24 * 60)
        #expect(sessions.isRunning == false)
        #expect(sessions.session?.isPaused == true)
        #expect(sessions.clock == nil)
    }

    @Test func resumingCarriesOnAndPicksTheClockBackUp() {
        sessions.start(.twentyFiveMinutes, on: task)
        stopwatch.advance(by: 60)
        sessions.pause()
        stopwatch.advance(by: 10 * 60)

        sessions.resume()

        #expect(sessions.isRunning)
        #expect(sessions.remaining == 24 * 60)

        stopwatch.advance(by: 60)
        letTheClockRun()

        #expect(sessions.remaining == 23 * 60)
    }

    @Test func aPausedSessionIsNotEndedByTimePassing() {
        sessions.start(.fifteenMinutes, on: task)
        sessions.pause()

        stopwatch.advance(by: 60 * 60)
        letTheClockRun()

        #expect(sessions.session?.task == task)
    }

    @Test func aSessionEndsItselfWhenItsTimeRunsOut() {
        sessions.start(.fifteenMinutes, on: task)

        stopwatch.advance(by: 15 * 60)
        letTheClockRun()

        #expect(sessions.session == nil)
        #expect(sessions.remaining == 0)
        #expect(sessions.clock == nil)
    }

    @Test func endingASessionClearsIt() {
        sessions.start(.twentyFiveMinutes, on: task)

        sessions.end()

        #expect(sessions.session == nil)
        #expect(sessions.isRunning == false)
        #expect(sessions.remaining == 0)
        #expect(sessions.clock == nil)
    }

    @Test func askingOfNoSessionAtAllChangesNothing() {
        sessions.pause()
        sessions.resume()
        sessions.end()

        #expect(sessions.session == nil)
        #expect(sessions.remaining == 0)
        #expect(sessions.clock == nil)
    }
}

@MainActor
private final class Stopwatch {
    private(set) var now: TimeInterval = 0

    func advance(by seconds: TimeInterval) {
        now += seconds
    }
}
