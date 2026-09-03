import AppKit
import QuartzCore
import SwiftUI

/// Owns the Notch Panel: puts it in the notch strip, keeps it there across Space
/// switches and display sleep, and drives its state from the cursor.
///
/// It lives as long as the app does, so the observers it installs are never
/// torn down.
@MainActor
final class NotchWindowController {

    let panel = NotchPanel()
    private let model = NotchPanelModel()
    private let tracking = NotchTrackingView()
    private let hosting: NSHostingView<NotchPanelView>

    private var metrics: NotchMetrics
    private var observers: [NSObjectProtocol] = []

    init() {
        metrics = Self.activeDisplayMetrics()
        hosting = NSHostingView(rootView: NotchPanelView(metrics: metrics, model: model))

        // The metrics decide how big the Panel is, not the content: SwiftUI's
        // own idea of a good size must not reach the window.
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

        watchTheCursor()
        watchTheDisplays()
        place(animated: false)
    }

    // MARK: The display

    /// Measures the Active Display. Following the cursor from one display to the
    /// next is its own issue; until then, prefer whichever screen has a notch.
    private static func activeDisplayMetrics() -> NotchMetrics {
        let screen =
            NSScreen.screens.first { $0.auxiliaryTopLeftArea != nil }
            ?? NSScreen.main
            ?? NSScreen.screens.first

        guard let screen else {
            // No display attached. Park the Panel until one arrives.
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

    /// Screens, Spaces or sleep moved the ground under us: measure the display
    /// again and put the Panel back on top. Waking a display in particular can
    /// leave the panel sitting behind the menu bar.
    private func remeasureAndRaise() {
        metrics = Self.activeDisplayMetrics()
        hosting.rootView = NotchPanelView(metrics: metrics, model: model)
        place(animated: false)
    }

    // MARK: The cursor

    private func watchTheCursor() {
        tracking.cursorIsOver = { [weak self] isOver in
            guard let self else { return }
            let previous = model.state
            model.cursorMoved(isOver: isOver)
            guard model.state != previous else { return }
            place(animated: true)
        }
    }

    // MARK: Placing the panel

    /// Where the Panel belongs right now. `place(animated:)` is the only thing
    /// that puts it there — anything else moving the window is a bug.
    var intendedFrame: NSRect {
        metrics.panelFrame(for: model.state)
    }

    private func place(animated: Bool) {
        let frame = intendedFrame
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(frame, display: true)
            }
        } else {
            panel.setFrame(frame, display: true)
        }
        panel.orderFrontRegardless()
    }
}
