import Foundation
import Observation

@MainActor
@Observable
final class FocusSessionModel {
    private(set) var session: FocusSession?
    private(set) var remaining: TimeInterval = 0

    @ObservationIgnored var sessionIsUnderway: (@MainActor (Bool) -> Void)?
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
        return session.isPaused == false && session.hasEnded(at: now()) == false
    }

    func start(_ duration: SessionDuration, on task: Task.ID) {
        session = FocusSession(task: task, duration: duration, startedAt: now())
        remaining = duration.seconds
        keepTime()
        sessionIsUnderway?(true)
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
        guard session != nil else { return }
        session = nil
        remaining = 0
        putTheClockDown()
        sessionIsUnderway?(false)
    }

    private func countDown() {
        guard let session else { return }
        let moment = now()
        remaining = session.remaining(at: moment)
        guard session.hasEnded(at: moment) else { return }
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
