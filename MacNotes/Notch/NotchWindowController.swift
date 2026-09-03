import AppKit
import QuartzCore
import SwiftUI

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

    private static func activeDisplayMetrics() -> NotchMetrics {
        let screen = NSScreen.main ?? NSScreen.screens.first

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
        metrics = Self.activeDisplayMetrics()
        hosting.rootView = NotchPanelView(metrics: metrics, model: model)
        place(animated: false)
    }

    private func watchTheCursor() {
        tracking.cursorIsOver = { [weak self] isOver in
            guard let self else { return }
            let previous = model.state
            model.cursorMoved(isOver: isOver)
            guard model.state != previous else { return }
            place(animated: true)
        }
    }

    var intendedFrame: NSRect {
        metrics.panelFrame(for: model.state)
    }

    private func place(animated: Bool) {
        let frame = intendedFrame
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
}
