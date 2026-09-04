import SwiftUI

struct NotchPanelView: View {
    let metrics: NotchMetrics
    let model: NotchPanelModel
    let sessions: FocusSessionModel

    private let cornerRadius: CGFloat = 10
    private let markerDiameter: CGFloat = 6

    var body: some View {
        let panel = metrics.panelFrame(for: model.state).size
        return VStack(spacing: 0) {
            strip
            if model.state == .expanded {
                readout
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
            flank(rounding: .bottomLeading)
            notch
                .frame(width: gap.width)
            flank(rounding: .bottomTrailing)
        }
        .frame(height: gap.height)
    }

    private func flank(rounding corner: Corner) -> some View {
        UnevenRoundedRectangle(
            bottomLeadingRadius: corner == .bottomLeading ? cornerRadius : 0,
            bottomTrailingRadius: corner == .bottomTrailing ? cornerRadius : 0
        )
        .fill(flankFill)
        .frame(maxWidth: .infinity)
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

    private var readout: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("MacNotes — \(model.state.name)")
                .font(.system(size: 12, weight: .semibold))
            Text("Notch \(size(metrics.notchRect)) · \(metrics.hasPhysicalNotch ? "physical" : "simulated")")
            Text("Display \(size(metrics.screenFrame))")
        }
        .font(.system(size: 10))
        .foregroundStyle(.white)
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.black, in: RoundedRectangle(cornerRadius: cornerRadius))
    }

    private func size(_ rect: CGRect) -> String {
        "\(Int(rect.width.rounded())) x \(Int(rect.height.rounded()))"
    }

    private enum Corner {
        case bottomLeading
        case bottomTrailing
    }
}
