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
        return VStack(spacing: 0) {
            strip
            if model.state == .expanded {
                TodayPanel(model: model, tasks: tasks, sessions: sessions)
                    .background(.black, in: RoundedRectangle(cornerRadius: cornerRadius))
            }
        }
        .frame(width: panel.width, height: panel.height, alignment: .top)
        .overlay(alignment: .top) { tray }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .clipped()
    }

    @ViewBuilder
    private var tray: some View {
        if model.state != .hidden, sessions.session != nil {
            let outline = trayOutline
            ProgressTray(
                grown: sessions.progress,
                reach: trayReach,
                panelCornerRadius: cornerRadius
            )
            .frame(width: outline.width, height: outline.height)
            .offset(y: outline.minY)
        }
    }

    private var trayReach: CGFloat {
        model.state == .expanded
            ? metrics.panelFrame(for: model.state).width / 2
            : metrics.notchGap(for: model.state).minX
    }

    private var trayOutline: CGRect {
        let panel = metrics.panelFrame(for: model.state)
        let strip = metrics.notchGap(for: model.state)
        guard model.state == .expanded else {
            return CGRect(x: 0, y: 0, width: panel.width, height: strip.height)
        }
        return CGRect(
            x: 0,
            y: strip.height,
            width: panel.width,
            height: panel.height - strip.height
        )
    }

    private var strip: some View {
        let gap = metrics.notchGap(for: model.state)
        return HStack(spacing: 0) {
            flank(rounding: .bottomLeading, carrying: runningTask)
            notch
                .frame(width: gap.width)
            flank(rounding: .bottomTrailing, carrying: runningTime)
        }
        .frame(height: gap.height)
    }

    private func flank<Content: View>(
        rounding corner: Corner,
        @ViewBuilder carrying content: () -> Content
    ) -> some View {
        UnevenRoundedRectangle(
            bottomLeadingRadius: corner == .bottomLeading ? cornerRadius : 0,
            bottomTrailingRadius: corner == .bottomTrailing ? cornerRadius : 0
        )
        .fill(flankFill)
        .overlay(alignment: corner == .bottomLeading ? .trailing : .leading, content: content)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func runningTask() -> some View {
        if model.state == .collapsed, let title = runningTitle {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
        }
    }

    @ViewBuilder
    private func runningTime() -> some View {
        if model.state == .collapsed, sessions.session != nil {
            Text(Countdown.text(sessions.remaining))
                .font(.system(size: 12, weight: .semibold).monospacedDigit())
                .foregroundStyle(sessions.isRunning ? Color.white : Color.white.opacity(0.5))
                .padding(.horizontal, 12)
        }
    }

    private var runningTitle: String? {
        sessions.session.flatMap { tasks.task($0.task)?.title }
    }

    private var notch: some View {
        Rectangle()
            .fill(notchFill)
            .overlay { marker }
            .allowsHitTesting(metrics.drawsItsOwnNotch)
    }

    @ViewBuilder
    private var marker: some View {
        if metrics.drawsItsOwnNotch && model.state == .hidden {
            Circle()
                .fill(.red)
                .frame(width: markerDiameter, height: markerDiameter)
        }
    }

    private var flankFill: Color {
        model.state == .collapsed ? .black : .clear
    }

    private var notchFill: Color {
        metrics.drawsItsOwnNotch && model.state != .hidden ? .black : .clear
    }

    private enum Corner {
        case bottomLeading
        case bottomTrailing
    }
}
