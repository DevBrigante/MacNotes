import Foundation

nonisolated struct AllottedTime: Codable, Equatable, Hashable, Sendable {
    static let presets = [10, 15, 25, 30, 45, 60]
    static let shortest = 1
    static let longest = 60
    static let standard = AllottedTime(minutes: 25)

    let minutes: Int

    init(minutes: Int) {
        self.minutes = min(max(minutes, Self.shortest), Self.longest)
    }

    var seconds: TimeInterval {
        TimeInterval(minutes * 60)
    }

    func stepped(by step: Int) -> AllottedTime {
        AllottedTime(minutes: minutes + step)
    }

    init(from decoder: any Decoder) throws {
        try self.init(minutes: decoder.singleValueContainer().decode(Int.self))
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(minutes)
    }
}
