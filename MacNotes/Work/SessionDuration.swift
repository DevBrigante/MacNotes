import Foundation

nonisolated enum SessionDuration: Int, CaseIterable, Codable, Sendable {
    case fifteenMinutes = 15
    case twentyFiveMinutes = 25
    case fortyFiveMinutes = 45
    case sixtyMinutes = 60

    var minutes: Int {
        rawValue
    }

    var seconds: TimeInterval {
        TimeInterval(minutes * 60)
    }
}
