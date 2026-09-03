import SwiftUI

/// The Notch Panel's skeleton, in the black of the notch: a strip beside the
/// camera when Collapsed, a panel hanging below the menu bar when Expanded, and
/// nothing at all when Hidden.
///
/// No Tasks and no Focus Session yet — this exists to prove the window lands on
/// the right strip of glass, and reads back what it measured so a human can
/// check it against the hardware.
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

    /// The row that lies in the menu bar. Only Collapsed draws anything here,
    /// and only beside the notch — the camera keeps its own strip of glass, and
    /// the menu bar keeps its items in every other state.
    private var strip: some View {
        let gap = metrics.notchGap(for: model.state)
        return HStack(spacing: 0) {
            flank(rounding: .bottomLeading)
                .frame(width: gap.minX)
            Color.clear
                .frame(width: gap.width)
                .allowsHitTesting(false)
            flank(rounding: .bottomTrailing)
        }
        .frame(height: gap.height)
    }

    private func flank(rounding corner: Corner) -> some View {
        UnevenRoundedRectangle(
            bottomLeadingRadius: corner == .bottomLeading ? cornerRadius : 0,
            bottomTrailingRadius: corner == .bottomTrailing ? cornerRadius : 0
        )
        .fill(model.state == .collapsed ? Color.black : Color.clear)
        .frame(maxWidth: .infinity)
    }

    /// What the Panel measured, so the placement can be judged on a real Mac.
    /// It hangs below the menu bar rather than across it.
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

    /// `1512 x 982` — the readout has no room for decimals.
    private func size(_ rect: CGRect) -> String {
        "\(Int(rect.width.rounded())) x \(Int(rect.height.rounded()))"
    }

    private enum Corner {
        case bottomLeading
        case bottomTrailing
    }
}
