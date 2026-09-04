import AppKit
import QuartzCore
import SwiftUI

@MainActor
final class NotchWindowController {
    let panel = NotchPanel()
    let sessions = FocusSessionModel()

    private let tasks: TaskStore
    private let model = NotchPanelModel()
    private let tracking = NotchTrackingView()
    private let hosting: NSHostingView<NotchPanelView>

    private var activeDisplay = ActiveDisplay()
    private var metrics: NotchMetrics
    private var observers: [NSObjectProtocol] = []
    private var sampler: Timer?

    init(tasks: TaskStore) {
        self.tasks = tasks
        metrics = Self.metrics(of: activeDisplay.screen)
        hosting = NSHostingView(
            rootView: NotchPanelView(
                metrics: metrics, model: model, sessions: sessions, tasks: tasks))

        hosting.sizingOptions = []
        hosting.translatesAutoresizingMaskIntoConstraints = false
        tracking.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: tracking.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: tracking.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: tracking.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: tracking.bottomAnchor),
        ])
        panel.contentView = tracking

        model.layoutChanged = { [weak self] in self?.placeIfNeeded() }
        watchTheCursor()
        watchTheSession()
        followTheCursorAcrossDisplays()
        watchTheDisplays()
        place(animated: false)
    }

    deinit {
        sampler?.invalidate()
    }

    private static func metrics(of screen: NSScreen?) -> NotchMetrics {
        guard let screen else {
            return NotchMetrics(screenFrame: .zero, notchRect: .zero, hasPhysicalNotch: false)
        }
        return NotchMetrics(screen: screen)
    }

    private func watchTheDisplays() {
        observe(NSApplication.didChangeScreenParametersNotification, on: .default)

        let workspace = NSWorkspace.shared.notificationCenter
        observe(NSWorkspace.didWakeNotification, on: workspace)
        observe(NSWorkspace.screensDidWakeNotification, on: workspace)
        observe(NSWorkspace.activeSpaceDidChangeNotification, on: workspace)
    }

    private func observe(_ name: Notification.Name, on center: NotificationCenter) {
        let observer = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.remeasureAndRaise() }
        }
        observers.append(observer)
    }

    private func remeasureAndRaise() {
        if activeDisplay.screen == nil {
            activeDisplay = ActiveDisplay()
        }
        metrics = Self.metrics(of: activeDisplay.screen)
        hosting.rootView = NotchPanelView(
            metrics: metrics, model: model, sessions: sessions, tasks: tasks)
        place(animated: false)
    }

    private func watchTheCursor() {
        tracking.cursorIsOver = { [weak self] isOver in
            self?.model.cursorMoved(isOver: isOver)
        }
    }

    private func watchTheSession() {
        sessions.sessionIsUnderway = { [weak self] isUnderway in
            self?.model.sessionChanged(isUnderway: isUnderway)
        }
    }

    private func placeIfNeeded() {
        guard panel.frame != intendedFrame else { return }
        place(animated: true)
    }

    private func followTheCursorAcrossDisplays() {
        let sampler = Timer(timeInterval: ActiveDisplay.sampling, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.sampleTheCursorsDisplay() }
        }
        sampler.tolerance = ActiveDisplay.sampling / 2
        RunLoop.main.add(sampler, forMode: .common)
        self.sampler = sampler
    }

    private func sampleTheCursorsDisplay() {
        guard let display = NSScreen.underTheCursor?.displayID else { return }
        let previous = activeDisplay.display
        activeDisplay.cursorMoved(to: display, at: ActiveDisplay.now)
        guard activeDisplay.display != previous else { return }
        remeasureAndRaise()
    }

    var intendedFrame: NSRect {
        metrics.panelFrame(for: model.state)
    }

    private func place(animated: Bool) {
        let frame = intendedFrame
        if model.state != .expanded { handBackTheKeyboard() }
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().setFrame(frame, display: true)
            }
        } else {
            panel.setFrame(frame, display: true)
        }
        panel.orderFrontRegardless()
    }

    private func handBackTheKeyboard() {
        guard panel.isKeyWindow else { return }
        panel.orderOut(nil)
    }
}
