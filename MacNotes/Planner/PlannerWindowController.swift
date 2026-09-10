import AppKit
import SwiftUI

@MainActor
final class PlannerWindowController: NSObject, NSWindowDelegate {
    let window: NSWindow

    var openChanged: (@MainActor (Bool) -> Void)?
    var appBecomesOrdinary: @MainActor (Bool) -> Void = { ordinary in
        NSApp.setActivationPolicy(ordinary ? .regular : .accessory)
        if ordinary { NSApp.activate(ignoringOtherApps: true) }
    }

    private let planner: PlannerModel

    init(tasks: TaskStore, sessions: FocusSessionModel, calendar: CalendarEvents? = nil) {
        planner = PlannerModel(tasks: tasks, sessions: sessions, calendar: calendar)
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 780, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        super.init()

        window.title = "Planner"
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 660, height: 420)
        window.contentView = NSHostingView(rootView: PlannerView(planner: planner))
        window.delegate = self
        window.center()
        window.setFrameAutosaveName("Planner")
    }

    var isOpen: Bool {
        window.isVisible
    }

    func open(on screen: NSScreen? = nil) {
        planner.show()
        appBecomesOrdinary(true)
        if let screen {
            window.setFrame(Self.frame(window.frame, centredIn: screen.visibleFrame), display: true)
        }
        window.makeKeyAndOrderFront(nil)
        openChanged?(true)
    }

    static func frame(_ window: NSRect, centredIn visibleFrame: NSRect) -> NSRect {
        NSRect(
            x: visibleFrame.midX - window.width / 2,
            y: visibleFrame.midY - window.height / 2,
            width: window.width,
            height: window.height
        )
    }

    func close() {
        guard window.isVisible else { return }
        window.close()
    }

    func windowWillClose(_ notification: Notification) {
        appBecomesOrdinary(false)
        openChanged?(false)
    }

    func windowDidBecomeKey(_ notification: Notification) {
        planner.refreshCalendar()
    }
}
