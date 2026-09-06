import AppKit
import Foundation
import Testing

@testable import MacNotes

private let task = UUID()
private let anotherTask = UUID()
private let tick: TimeInterval = 0.05

@MainActor
final class FocusSessionModelTests {
    private let stopwatch = Stopwatch()
    private let workspace = NotificationCenter()
    private let sessions: FocusSessionModel

    init() {
        let stopwatch = self.stopwatch
        sessions = FocusSessionModel(now: { stopwatch.now }, tick: tick, workspace: workspace)
    }

    private func closeTheLid() {
        workspace.post(name: NSWorkspace.willSleepNotification, object: nil)
        letTheClockRun()
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
        sessions.start(.init(minutes: 25), on: task)

        #expect(sessions.session?.task == task)
        #expect(sessions.isRunning)
        #expect(sessions.remaining == 25 * 60)
        #expect(sessions.clock != nil)
    }

    @Test func theRemainingTimeFollowsTheClock() {
        sessions.start(.init(minutes: 25), on: task)

        stopwatch.advance(by: 60)
        letTheClockRun()

        #expect(sessions.remaining == 24 * 60)
    }

    @Test func startingOnAnotherTaskLeavesNoTraceOfThePreviousSession() {
        sessions.start(.init(minutes: 25), on: task)
        stopwatch.advance(by: 5 * 60)

        sessions.start(.init(minutes: 15), on: anotherTask)

        #expect(sessions.session?.task == anotherTask)
        #expect(sessions.remaining == 15 * 60)
    }

    @Test func switchingLeavesNoSecondClockBehind() {
        sessions.start(.init(minutes: 25), on: task)
        let clock = sessions.clock

        sessions.start(.init(minutes: 15), on: anotherTask)

        #expect(sessions.clock === clock)
    }

    @Test func aSessionSwitchedAwayFromNeverRunsOutLater() {
        sessions.start(.init(minutes: 15), on: task)
        sessions.start(.init(minutes: 60), on: anotherTask)

        stopwatch.advance(by: 15 * 60)
        letTheClockRun()

        #expect(sessions.session?.task == anotherTask)
        #expect(sessions.remaining == 45 * 60)
    }

    @Test func pausingHoldsTheTimeStillAndPutsTheClockDown() {
        sessions.start(.init(minutes: 25), on: task)
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
        sessions.start(.init(minutes: 25), on: task)
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
        sessions.start(.init(minutes: 15), on: task)
        sessions.pause()

        stopwatch.advance(by: 60 * 60)
        letTheClockRun()

        #expect(sessions.session?.task == task)
    }

    @Test func aSessionEndsItselfWhenItsTimeRunsOut() {
        sessions.start(.init(minutes: 15), on: task)

        stopwatch.advance(by: 15 * 60)
        letTheClockRun()

        #expect(sessions.session == nil)
        #expect(sessions.remaining == 0)
        #expect(sessions.clock == nil)
    }

    @Test func endingASessionClearsIt() {
        sessions.start(.init(minutes: 25), on: task)

        sessions.end()

        #expect(sessions.session == nil)
        #expect(sessions.isRunning == false)
        #expect(sessions.remaining == 0)
        #expect(sessions.clock == nil)
    }

    @Test func aSessionIsNoLongerRunningTheMomentItsTimeIsUp() {
        sessions.start(.init(minutes: 15), on: task)

        stopwatch.advance(by: 15 * 60)

        #expect(sessions.isRunning == false)
    }

    @Test func theProgressGrowsAsTheSessionRuns() {
        sessions.start(.init(minutes: 15), on: task)

        #expect(sessions.progress == 0)

        stopwatch.advance(by: 225)
        letTheClockRun()

        #expect(sessions.progress == 0.25)

        stopwatch.advance(by: 450)
        letTheClockRun()

        #expect(sessions.progress == 0.75)
    }

    @Test func theProgressHoldsStillWhilePaused() {
        sessions.start(.init(minutes: 15), on: task)
        stopwatch.advance(by: 450)

        sessions.pause()
        stopwatch.advance(by: 60 * 60)
        letTheClockRun()

        #expect(sessions.progress == 0.5)
    }

    @Test func switchingTaskStartsTheProgressOverFromEmpty() {
        sessions.start(.init(minutes: 15), on: task)
        stopwatch.advance(by: 675)
        letTheClockRun()

        sessions.start(.init(minutes: 60), on: anotherTask)

        #expect(sessions.progress == 0)
    }

    @Test func thereIsNoProgressWithoutASession() {
        #expect(sessions.progress == 0)

        sessions.start(.init(minutes: 15), on: task)
        stopwatch.advance(by: 450)
        letTheClockRun()
        sessions.end()

        #expect(sessions.progress == 0)
    }

    @Test func aSessionStartingSaysSo() {
        var underway: [Bool] = []
        sessions.sessionIsUnderway = { underway.append($0) }

        sessions.start(.init(minutes: 25), on: task)

        #expect(underway == [true])
    }

    @Test func aSessionRunningOutSaysSo() {
        sessions.start(.init(minutes: 15), on: task)
        var underway: [Bool] = []
        sessions.sessionIsUnderway = { underway.append($0) }

        stopwatch.advance(by: 15 * 60)
        letTheClockRun()

        #expect(underway == [false])
    }

    @Test func aPausedSessionIsStillUnderway() {
        var underway: [Bool] = []
        sessions.sessionIsUnderway = { underway.append($0) }

        sessions.start(.init(minutes: 25), on: task)
        sessions.pause()
        sessions.resume()

        #expect(underway == [true])
    }

    @Test func theMacGoingToSleepEndsTheSession() {
        sessions.start(.init(minutes: 25), on: task)

        closeTheLid()

        #expect(sessions.session == nil)
        #expect(sessions.remaining == 0)
        #expect(sessions.clock == nil)
    }

    @Test func theMacGoingToSleepEndsAPausedSessionToo() {
        sessions.start(.init(minutes: 25), on: task)
        sessions.pause()

        closeTheLid()

        #expect(sessions.session == nil)
    }

    @Test func theMacGoingToSleepSaysTheSessionIsOver() {
        sessions.start(.init(minutes: 25), on: task)
        var underway: [Bool] = []
        sessions.sessionIsUnderway = { underway.append($0) }

        closeTheLid()

        #expect(underway == [false])
    }

    @Test func theMacSleepingWithNoSessionSaysNothing() {
        var underway: [Bool] = []
        sessions.sessionIsUnderway = { underway.append($0) }

        closeTheLid()

        #expect(underway.isEmpty)
    }

    @Test func askingOfNoSessionAtAllChangesNothing() {
        var underway: [Bool] = []
        sessions.sessionIsUnderway = { underway.append($0) }

        sessions.pause()
        sessions.resume()
        sessions.end()

        #expect(sessions.session == nil)
        #expect(sessions.remaining == 0)
        #expect(sessions.clock == nil)
        #expect(underway.isEmpty)
    }
}

@MainActor
final class FocusSessionControlTests {
    private let stopwatch = Stopwatch()
    private let sessions: FocusSessionModel

    init() {
        let stopwatch = self.stopwatch
        sessions = FocusSessionModel(
            now: { stopwatch.now }, tick: tick, workspace: NotificationCenter())
    }

    @Test func onePressStartsTheSessionAtTheTimeTheTaskCarries() {
        let waiting = Task(title: "Book the flight", allotted: AllottedTime(minutes: 45))

        sessions.startOrPause(waiting)

        #expect(sessions.session?.task == waiting.id)
        #expect(sessions.remaining == 45 * 60)
    }

    @Test func theNextPressOnTheSameTaskPausesAndTheOneAfterResumes() {
        let waiting = Task(title: "Book the flight")

        sessions.startOrPause(waiting)
        sessions.startOrPause(waiting)

        #expect(sessions.isRunning == false)
        #expect(sessions.session?.isPaused == true)

        sessions.startOrPause(waiting)

        #expect(sessions.isRunning)
    }

    @Test func pressingAnotherTaskMovesTheSessionOntoIt() {
        let waiting = Task(title: "Book the flight")
        let other = Task(title: "Renew the passport", allotted: AllottedTime(minutes: 10))

        sessions.startOrPause(waiting)
        sessions.startOrPause(other)

        #expect(sessions.session?.task == other.id)
        #expect(sessions.remaining == 10 * 60)
    }

    @Test func deletingTheTaskUnderTheSessionEndsIt() {
        let going = Task(title: "Book the flight")
        var underway: [Bool] = []
        sessions.startOrPause(going)
        sessions.sessionIsUnderway = { underway.append($0) }

        sessions.endTheSession(on: going.id)

        #expect(sessions.session == nil)
        #expect(underway == [false])
    }

    @Test func deletingAnyOtherTaskLeavesTheSessionRunning() {
        let running = Task(title: "Book the flight")
        sessions.startOrPause(running)

        sessions.endTheSession(on: UUID())

        #expect(sessions.session?.task == running.id)
        #expect(sessions.isRunning)
    }
}

@MainActor
private final class Stopwatch {
    private(set) var now: TimeInterval = 0

    func advance(by seconds: TimeInterval) {
        now += seconds
    }
}
