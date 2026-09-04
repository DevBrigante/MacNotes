import Foundation
import Observation

@MainActor
@Observable
final class FocusSessionModel {
    private(set) var session: FocusSession?
    private(set) var remaining: TimeInterval = 0

    @ObservationIgnored private(set) var clock: Timer?
    @ObservationIgnored private let now: @MainActor () -> TimeInterval
    @ObservationIgnored private let tick: TimeInterval

    init(
        now: @escaping @MainActor () -> TimeInterval = { FocusSession.now },
        tick: TimeInterval = 0.5
    ) {
        self.now = now
        self.tick = tick
    }

    deinit {
        clock?.invalidate()
    }

    var isRunning: Bool {
        guard let session else { return false }
        return session.isPaused == false
    }

    func start(_ duration: SessionDuration, on task: Task.ID) {
        session = FocusSession(task: task, duration: duration, startedAt: now())
        remaining = duration.seconds
        keepTime()
    }

    func pause() {
        guard var session, session.isPaused == false else { return }
        session.pause(at: now())
        self.session = session
        putTheClockDown()
        countDown()
    }

    func resume() {
        guard var session, session.isPaused else { return }
        session.resume(at: now())
        self.session = session
        keepTime()
        countDown()
    }

    func end() {
        session = nil
        remaining = 0
        putTheClockDown()
    }

    private func countDown() {
        guard let session else { return }
        remaining = session.remaining(at: now())
        guard remaining == 0 else { return }
        end()
    }

    private func keepTime() {
        guard clock == nil else { return }
        let clock = Timer(timeInterval: tick, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.countDown() }
        }
        clock.tolerance = tick / 4
        RunLoop.main.add(clock, forMode: .common)
        self.clock = clock
    }

    private func putTheClockDown() {
        clock?.invalidate()
        clock = nil
    }
}
