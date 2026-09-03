import SwiftUI

struct NotchPanelView: View {
    let metrics: NotchMetrics
    let model: NotchPanelModel

    private let cornerRadius: CGFloat = 10

    var body: some View {
        VStack(spacing: 0) {
            strip
            if model.state == .expanded {
                readout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var strip: some View {
        let gap = metrics.notchGap(for: model.state)
        return HStack(spacing: 0) {
            flank(rounding: .bottomLeading)
                .frame(width: gap.minX)
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
            .allowsHitTesting(metrics.drawsItsOwnNotch)
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
