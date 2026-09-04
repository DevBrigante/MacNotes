import CoreGraphics
import Foundation
import Testing

@testable import MacNotes

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

private func externalDisplay(menuBarHeight: CGFloat = 24) -> NotchMetrics {
    NotchMetrics(
        screenFrame: CGRect(x: 1512, y: 0, width: 2560, height: 1440),
        auxiliaryTopLeft: nil,
        auxiliaryTopRight: nil,
        menuBarHeight: menuBarHeight
    )
}

struct NotchMetricsTests {
    @Test func readsThePhysicalNotchFromTheAuxiliaryAreas() {
        let metrics = builtInDisplay()

        #expect(metrics.hasPhysicalNotch)
        #expect(metrics.drawsItsOwnNotch == false)
        #expect(metrics.notchRect.width == notchWidth)
        #expect(metrics.notchRect.height == stripHeight)
        #expect(metrics.notchRect.midX == metrics.screenFrame.midX)
        #expect(metrics.notchRect.maxY == metrics.screenFrame.maxY)
    }

    @Test func placesTheNotchRelativeToItsOwnDisplay() {
        let secondary = CGRect(x: -1512, y: 200, width: 1512, height: 982)
        let metrics = builtInDisplay(screenFrame: secondary)

        #expect(metrics.notchRect.midX == secondary.midX)
        #expect(metrics.notchRect.maxY == secondary.maxY)
    }

    @Test func simulatesANotchWhereTheDisplayHasNone() {
        let metrics = externalDisplay()

        #expect(metrics.drawsItsOwnNotch)
        #expect(metrics.notchRect.width == NotchMetrics.simulatedNotchWidth)
        #expect(metrics.notchRect.midX == metrics.screenFrame.midX)
        #expect(metrics.notchRect.maxY == metrics.screenFrame.maxY)
    }

    @Test func theSimulatedNotchIsAsTallAsThatDisplaysMenuBar() {
        #expect(externalDisplay(menuBarHeight: 24).notchRect.height == 24)
        #expect(externalDisplay(menuBarHeight: 37).notchRect.height == 37)
    }

    @Test func hiddenNeverHangsBelowTheMenuBar() {
        let metrics = externalDisplay(menuBarHeight: 24)

        #expect(metrics.panelFrame(for: .hidden).height == 24)
    }

    @Test(arguments: Display.allCases)
    func collapsedHangsTheSameTenPointsOnEveryDisplay(display: Display) {
        let metrics = display.metrics

        #expect(
            metrics.panelFrame(for: .collapsed).height
                == metrics.notchRect.height + NotchMetrics.Layout.collapsedDrop)
    }

    @Test func settingAnAllottedTimeGrowsOnlyTheExpandedPanel() {
        let metrics = builtInDisplay()

        #expect(
            metrics.panelFrame(for: .expanded, allotting: true).height
                - metrics.panelFrame(for: .expanded).height
                == NotchMetrics.Layout.allottingDrop)
        #expect(
            metrics.panelFrame(for: .collapsed, allotting: true)
                == metrics.panelFrame(for: .collapsed))
        #expect(
            metrics.panelFrame(for: .hidden, allotting: true)
                == metrics.panelFrame(for: .hidden))
    }

    @Test func measuresTheMenuBarOnTheDisplayItIsGiven() {
        let frame = CGRect(x: 0, y: 0, width: 2560, height: 1440)
        let visible = CGRect(x: 0, y: 0, width: 2560, height: 1416)

        #expect(
            NotchMetrics.menuBarHeight(
                frame: frame, visibleFrame: visible, statusBarThickness: 24) == 24)
    }

    @Test func fallsBackToTheSystemMenuBarWhereTheDisplayDrawsNone() {
        let frame = CGRect(x: 0, y: 0, width: 2560, height: 1440)

        #expect(
            NotchMetrics.menuBarHeight(
                frame: frame, visibleFrame: frame, statusBarThickness: 24) == 24)
    }

    @Test func hiddenFitsTheNotchSilhouette() {
        #expect(builtInDisplay().panelFrame(for: .hidden) == builtInDisplay().notchRect)
        #expect(externalDisplay().panelFrame(for: .hidden) == externalDisplay().notchRect)
    }

    @Test func collapsedFlanksTheNotchOnBothSides() {
        let metrics = builtInDisplay()
        let frame = metrics.panelFrame(for: .collapsed)

        #expect(frame.width == notchWidth + 2 * NotchMetrics.Layout.collapsedFlank)
        #expect(frame.height == stripHeight + NotchMetrics.Layout.collapsedDrop)
    }

    @Test(arguments: Display.allCases)
    func expandedHangsBelowTheStrip(display: Display) {
        let metrics = display.metrics
        let collapsed = metrics.panelFrame(for: .collapsed)
        let expanded = metrics.panelFrame(for: .expanded)

        #expect(expanded.height > collapsed.height)
        #expect(expanded.width > collapsed.width)
        #expect(expanded.minY < collapsed.minY)
    }

    @Test(arguments: NotchPanelState.allCases, Display.allCases)
    func everyStateHangsFromTheTopOfTheScreen(state: NotchPanelState, display: Display) {
        let metrics = display.metrics

        #expect(metrics.panelFrame(for: state).maxY == metrics.screenFrame.maxY)
    }

    @Test(arguments: NotchPanelState.allCases, Display.allCases)
    func everyStateLeavesTheNotchEmpty(state: NotchPanelState, display: Display) {
        let metrics = display.metrics
        let frame = metrics.panelFrame(for: state)
        let gap = metrics.notchGap(for: state)

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

    enum Display: CaseIterable {
        case builtIn
        case external

        var metrics: NotchMetrics {
            switch self {
            case .builtIn: builtInDisplay()
            case .external: externalDisplay()
            }
        }
    }
}
