import AppKit
import CoreGraphics
import Foundation

nonisolated struct ActiveDisplay: Equatable {
    static let dwell: TimeInterval = 1
    static let sampling: TimeInterval = dwell / 4

    static var now: TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }

    private(set) var display: CGDirectDisplayID
    private var candidate: Candidate?

    init(display: CGDirectDisplayID) {
        self.display = display
    }

    mutating func cursorMoved(to display: CGDirectDisplayID, at time: TimeInterval) {
        guard display != self.display else {
            candidate = nil
            return
        }
        guard let candidate, candidate.display == display else {
            candidate = Candidate(display: display, since: time)
            return
        }
        guard time - candidate.since >= Self.dwell else { return }

        self.display = display
        self.candidate = nil
    }

    private struct Candidate: Equatable {
        let display: CGDirectDisplayID
        let since: TimeInterval
    }
}

extension ActiveDisplay {
    @MainActor
    init() {
        self.init(display: NSScreen.underTheCursor?.displayID ?? CGMainDisplayID())
    }

    @MainActor
    var screen: NSScreen? {
        NSScreen.screens.first { $0.displayID == display }
    }
}

extension NSScreen {
    static var underTheCursor: NSScreen? {
        let cursor = NSEvent.mouseLocation
        return screens.first { NSMouseInRect(cursor, $0.frame, false) }
    }

    var displayID: CGDirectDisplayID {
        let number = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        return number.map { CGDirectDisplayID($0.uint32Value) } ?? CGMainDisplayID()
    }
}
