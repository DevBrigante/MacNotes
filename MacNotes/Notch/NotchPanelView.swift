import SwiftUI

struct NotchPanelView: View {
    let metrics: NotchMetrics
    let model: NotchPanelModel
    let sessions: FocusSessionModel
    let tasks: TaskStore

    private let cornerRadius: CGFloat = 10
    private let markerDiameter: CGFloat = 6

    var body: some View {
        let panel = metrics.panelFrame(for: model.state).size
        return ZStack(alignment: .top) {
            surface
            content
            tray
        }
        .frame(width: panel.width, height: panel.height, alignment: .top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .clipped()
    }

    @ViewBuilder
    private var surface: some View {
        if model.state != .hidden {
            UnevenRoundedRectangle(
                bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: cornerRadius
            )
            .fill(.black)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .hidden: marker
        case .collapsed: readout
        case .expanded: today
        }
    }

    @ViewBuilder
    private var marker: some View {
        if metrics.drawsItsOwnNotch {
            Circle()
                .fill(.red)
                .frame(width: markerDiameter, height: markerDiameter)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var readout: some View {
        let gap = metrics.notchGap(for: .collapsed)
        return HStack(spacing: 0) {
            runningTask
                .frame(width: gap.minX, alignment: .leading)
            Spacer(minLength: 0)
                .frame(width: gap.width)
            runningTime
                .frame(width: gap.minX, alignment: .trailing)
        }
        .frame(height: gap.height)
    }

    @ViewBuilder
    private var runningTask: some View {
        if let title = runningTitle {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
        }
    }

    @ViewBuilder
    private var runningTime: some View {
        if sessions.session != nil {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.system(size: 10, weight: .semibold))
                Text(Countdown.text(sessions.remaining))
                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
            }
            .foregroundStyle(sessions.isRunning ? Color.white : Color.white.opacity(0.5))
            .padding(.horizontal, 12)
        }
    }

    private var runningTitle: String? {
        sessions.session.flatMap { tasks.task($0.task)?.title }
    }

    private var today: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: metrics.notchGap(for: .expanded).height)
            TodayPanel(model: model, tasks: tasks, sessions: sessions)
        }
    }

    @ViewBuilder
    private var tray: some View {
        if model.state != .hidden, sessions.session != nil {
            ProgressTray(grown: sessions.progress, panelCornerRadius: cornerRadius)
        }
    }
}
