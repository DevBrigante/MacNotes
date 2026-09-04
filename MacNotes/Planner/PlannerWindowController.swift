import AppKit
import SwiftUI

@MainActor
final class PlannerWindowController: NSObject, NSWindowDelegate {
    let window: NSWindow

    var openChanged: (@MainActor (Bool) -> Void)?
    var appBecomesOrdinary: @MainActor (Bool) -> Void = { ordinary in
        NSApp.setActivationPolicy(ordinary ? .regular : .accessory)
        if ordinary { NSApp.activate() }
    }

    private let planner: PlannerModel

    init(tasks: TaskStore, sessions: FocusSessionModel) {
        planner = PlannerModel(tasks: tasks, sessions: sessions)
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

    func open() {
        planner.show()
        appBecomesOrdinary(true)
        window.makeKeyAndOrderFront(nil)
        openChanged?(true)
    }

    func close() {
        guard window.isVisible else { return }
        window.close()
    }

    func windowWillClose(_ notification: Notification) {
        appBecomesOrdinary(false)
        openChanged?(false)
    }
}
