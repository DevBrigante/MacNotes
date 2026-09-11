import AppKit
import CoreGraphics

nonisolated struct NotchReadout: Equatable, Sendable {
    let showsTaskTitle: Bool
    let showsTimer: Bool

    static let all = NotchReadout(showsTaskTitle: true, showsTimer: true)

    var isEmpty: Bool {
        showsTaskTitle == false && showsTimer == false
    }
}

nonisolated struct NotchMetrics: Equatable {
    enum Layout {
        static let collapsedFlank: CGFloat = 72
        static let wideCollapsedFlank: CGFloat = 88
        static let expandedFlank: CGFloat = 132
        static let collapsedDrop: CGFloat = 10
        static let expandedDrop: CGFloat = 140
    }

    static let simulatedNotchWidth: CGFloat = 200

    let screenFrame: CGRect
    let notchRect: CGRect
    let hasPhysicalNotch: Bool

    init(screenFrame: CGRect, notchRect: CGRect, hasPhysicalNotch: Bool) {
        self.screenFrame = screenFrame
        self.notchRect = notchRect
        self.hasPhysicalNotch = hasPhysicalNotch
    }

    init(
        screenFrame: CGRect,
        auxiliaryTopLeft: CGRect?,
        auxiliaryTopRight: CGRect?,
        menuBarHeight: CGFloat
    ) {
        self.screenFrame = screenFrame

        if let left = auxiliaryTopLeft, let right = auxiliaryTopRight,
            left.width + right.width < screenFrame.width
        {
            let height = max(left.height, right.height)
            self.notchRect = CGRect(
                x: screenFrame.minX + left.width,
                y: screenFrame.maxY - height,
                width: screenFrame.width - left.width - right.width,
                height: height
            )
            self.hasPhysicalNotch = true
        } else {
            let height = max(menuBarHeight, 1)
            self.notchRect = CGRect(
                x: screenFrame.midX - Self.simulatedNotchWidth / 2,
                y: screenFrame.maxY - height,
                width: Self.simulatedNotchWidth,
                height: height
            )
            self.hasPhysicalNotch = false
        }
    }

    var drawsItsOwnNotch: Bool {
        hasPhysicalNotch == false
    }

    func panelFrame(
        for state: NotchPanelState,
        allotted: AllottedTime? = nil,
        readout: NotchReadout = .all
    ) -> CGRect {
        let flanks = flankWidths(for: state, allotted: allotted, readout: readout)
        let width = (notchRect.width + flanks.leading + flanks.trailing).rounded()
        let height = (notchRect.height + drop(for: state, readout: readout)).rounded()
        return CGRect(
            x: (notchRect.minX - flanks.leading).rounded(),
            y: screenFrame.maxY - height,
            width: width,
            height: height
        )
    }

    func notchGap(
        for state: NotchPanelState,
        allotted: AllottedTime? = nil,
        readout: NotchReadout = .all
    ) -> CGRect {
        CGRect(
            x: notchRect.minX - panelFrame(for: state, allotted: allotted, readout: readout).minX,
            y: 0,
            width: notchRect.width,
            height: notchRect.height
        )
    }

    private func flankWidths(
        for state: NotchPanelState,
        allotted: AllottedTime?,
        readout: NotchReadout
    ) -> (leading: CGFloat, trailing: CGFloat) {
        switch state {
        case .hidden:
            return (0, 0)
        case .collapsed:
            let width = allotted.map { $0.minutes >= 10 } == true
                ? Layout.wideCollapsedFlank
                : Layout.collapsedFlank
            return (
                readout.showsTaskTitle ? width : 0,
                readout.showsTimer ? width : 0
            )
        case .expanded:
            return (Layout.expandedFlank, Layout.expandedFlank)
        }
    }

    private func drop(for state: NotchPanelState, readout: NotchReadout = .all) -> CGFloat {
        switch state {
        case .hidden: 0
        case .collapsed: readout.isEmpty ? 0 : Layout.collapsedDrop
        case .expanded: Layout.expandedDrop
        }
    }
}

extension NotchMetrics {
    @MainActor
    init(screen: NSScreen) {
        self.init(
            screenFrame: screen.frame,
            auxiliaryTopLeft: screen.auxiliaryTopLeftArea,
            auxiliaryTopRight: screen.auxiliaryTopRightArea,
            menuBarHeight: Self.menuBarHeight(
                frame: screen.frame,
                visibleFrame: screen.visibleFrame,
                statusBarThickness: NSStatusBar.system.thickness
            )
        )
    }

    static func menuBarHeight(
        frame: CGRect,
        visibleFrame: CGRect,
        statusBarThickness: CGFloat
    ) -> CGFloat {
        max(frame.maxY - visibleFrame.maxY, statusBarThickness)
    }
}
