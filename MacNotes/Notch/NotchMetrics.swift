import AppKit
import CoreGraphics

nonisolated struct NotchMetrics: Equatable {
    enum Layout {
        static let collapsedFlank: CGFloat = 72
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

    func panelFrame(for state: NotchPanelState) -> CGRect {
        let width = (notchRect.width + 2 * flankWidth(for: state)).rounded()
        let height = (notchRect.height + drop(for: state)).rounded()
        return CGRect(
            x: (notchRect.midX - width / 2).rounded(),
            y: screenFrame.maxY - height,
            width: width,
            height: height
        )
    }

    func notchGap(for state: NotchPanelState) -> CGRect {
        CGRect(
            x: notchRect.minX - panelFrame(for: state).minX,
            y: 0,
            width: notchRect.width,
            height: notchRect.height
        )
    }

    func flankWidth(for state: NotchPanelState) -> CGFloat {
        switch state {
        case .hidden: 0
        case .collapsed: Layout.collapsedFlank
        case .expanded: Layout.expandedFlank
        }
    }

    private func drop(for state: NotchPanelState) -> CGFloat {
        switch state {
        case .hidden: 0
        case .collapsed: Layout.collapsedDrop
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
