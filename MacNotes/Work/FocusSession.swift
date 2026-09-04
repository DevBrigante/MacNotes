import Foundation

nonisolated struct FocusSession: Equatable, Sendable {
    let task: Task.ID
    let allotted: AllottedTime

    private var state: State

    init(task: Task.ID, allotted: AllottedTime, startedAt now: TimeInterval) {
        self.task = task
        self.allotted = allotted
        state = .running(until: now + allotted.seconds)
    }

    var isPaused: Bool {
        if case .paused = state { return true }
        return false
    }

    func remaining(at now: TimeInterval) -> TimeInterval {
        switch state {
        case .running(let until): max(0, until - now)
        case .paused(let remaining): remaining
        }
    }

    func hasEnded(at now: TimeInterval) -> Bool {
        remaining(at: now) == 0
    }

    mutating func pause(at now: TimeInterval) {
        guard case .running = state else { return }
        state = .paused(remaining: remaining(at: now))
    }

    mutating func resume(at now: TimeInterval) {
        guard case .paused(let remaining) = state else { return }
        state = .running(until: now + remaining)
    }

    private enum State: Equatable {
        case running(until: TimeInterval)
        case paused(remaining: TimeInterval)
    }
}

extension FocusSession {
    private static let origin = ContinuousClock.now

    static var now: TimeInterval {
        (ContinuousClock.now - origin) / .seconds(1)
    }
}
