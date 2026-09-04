import Foundation

nonisolated enum Countdown {
    static func text(_ remaining: TimeInterval) -> String {
        let seconds = Int(max(0, remaining).rounded(.up))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
