import CoreGraphics
import Foundation
import Testing

@testable import MacNotes

/// A 14" MacBook Pro as `NSScreen` describes it: a 200pt notch centred in a
/// 37pt strip at the top of a 1512x982 display.
private let screenFrame = CGRect(x: 0, y: 0, width: 1512, height: 982)
private let stripHeight: CGFloat = 37
private let notchWidth: CGFloat = 200

private func builtInDisplay(
    screenFrame: CGRect = screenFrame,
    notchWidth: CGFloat = notchWidth
) -> NotchMetrics {
    let flank = (screenFrame.width - notchWidth) / 2
    return NotchMetrics(
        screenFrame: screenFrame,
        auxiliaryTopLeft: CGRect(
            x: screenFrame.minX, y: screenFrame.maxY - stripHeight,
            width: flank, height: stripHeight),
        auxiliaryTopRight: CGRect(
            x: screenFrame.maxX - flank, y: screenFrame.maxY - stripHeight,
            width: flank, height: stripHeight),
        menuBarHeight: 24
    )
}

private func externalDisplay() -> NotchMetrics {
    NotchMetrics(
        screenFrame: CGRect(x: 1512, y: 0, width: 2560, height: 1440),
        auxiliaryTopLeft: nil,
        auxiliaryTopRight: nil,
        menuBarHeight: 24
    )
}

struct NotchMetricsTests {

    // MARK: Reading the display

    @Test func readsThePhysicalNotchFromTheAuxiliaryAreas() {
        let metrics = builtInDisplay()

        #expect(metrics.hasPhysicalNotch)
        #expect(metrics.notchRect.width == notchWidth)
        #expect(metrics.notchRect.height == stripHeight)
        #expect(metrics.notchRect.midX == screenFrame.midX)
        #expect(metrics.notchRect.maxY == screenFrame.maxY)
    }

    @Test func placesTheNotchRelativeToItsOwnDisplay() {
        let secondary = CGRect(x: -1512, y: 200, width: 1512, height: 982)
        let metrics = builtInDisplay(screenFrame: secondary)

        #expect(metrics.notchRect.midX == secondary.midX)
        #expect(metrics.notchRect.maxY == secondary.maxY)
    }

    @Test func placesThePanelOnADisplayWithNoNotchAtAll() {
        let metrics = externalDisplay()

        #expect(metrics.hasPhysicalNotch == false)
        #expect(metrics.notchRect.width == NotchMetrics.placeholderNotchWidth)
        #expect(metrics.notchRect.height == 24)
        #expect(metrics.notchRect.midX == metrics.screenFrame.midX)
        #expect(metrics.notchRect.maxY == metrics.screenFrame.maxY)
    }

    // MARK: Placing the panel

    @Test func hiddenFitsTheNotchSilhouette() {
        #expect(builtInDisplay().panelFrame(for: .hidden) == builtInDisplay().notchRect)
    }

    @Test func collapsedFlanksTheNotchOnBothSides() {
        let metrics = builtInDisplay()
        let frame = metrics.panelFrame(for: .collapsed)

        #expect(frame.width == notchWidth + 2 * NotchMetrics.Layout.collapsedFlank)
        #expect(frame.height == stripHeight)
    }

    @Test func expandedHangsBelowTheStrip() {
        let metrics = builtInDisplay()
        let collapsed = metrics.panelFrame(for: .collapsed)
        let expanded = metrics.panelFrame(for: .expanded)

        #expect(expanded.height > collapsed.height)
        #expect(expanded.width > collapsed.width)
        #expect(expanded.minY < collapsed.minY)
    }

    @Test(arguments: NotchPanelState.allCases)
    func everyStateHangsFromTheTopOfTheScreen(state: NotchPanelState) {
        let metrics = builtInDisplay()

        #expect(metrics.panelFrame(for: state).maxY == screenFrame.maxY)
    }

    @Test(arguments: NotchPanelState.allCases)
    func everyStateLeavesTheNotchEmpty(state: NotchPanelState) {
        let metrics = builtInDisplay()
        let frame = metrics.panelFrame(for: state)
        let gap = metrics.notchGap(for: state)

        // The gap is expressed in the panel's own space, top-left origin. Put it
        // back into screen coordinates: it has to land on the camera, exactly.
        #expect(abs(frame.minX + gap.minX - metrics.notchRect.minX) <= 1)
        #expect(gap.width == metrics.notchRect.width)
        #expect(gap.height == metrics.notchRect.height)
        #expect(gap.minY == 0)
        #expect(gap.minX >= 0)
        #expect(gap.maxX <= frame.width)
    }

    @Test(arguments: NotchPanelState.allCases)
    func everyStateIsBalancedAroundTheNotch(state: NotchPanelState) {
        let metrics = builtInDisplay(notchWidth: 201)
        let frame = metrics.panelFrame(for: state)
        let gap = metrics.notchGap(for: state)

        #expect(abs(gap.minX - (frame.width - gap.maxX)) <= 1)
    }
}
