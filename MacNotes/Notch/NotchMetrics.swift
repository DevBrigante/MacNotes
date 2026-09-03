import AppKit
import CoreGraphics

/// Where the Notch Panel sits on a display.
///
/// Pure geometry: it takes the numbers a screen reports and hands back the frame
/// the Panel occupies in each state, so placement can be reasoned about — and
/// tested — without a MacBook attached.
///
/// All rectangles are in screen coordinates, origin bottom-left, like
/// `NSScreen.frame`.
nonisolated struct NotchMetrics: Equatable {

    /// Fixed sizes of the Notch Panel's silhouette, in points.
    enum Layout {
        /// How far the strip reaches past the notch on each side when Collapsed —
        /// only as far as the Session's remaining time and its Task need, so the
        /// menu bar keeps as much of itself as possible. Sized for real content
        /// when there is a Focus Session to size it against.
        static let collapsedFlank: CGFloat = 72
        /// …and when Expanded.
        static let expandedFlank: CGFloat = 132
        /// How far the Expanded Panel hangs below the strip.
        static let expandedDrop: CGFloat = 168
    }

    /// Width of the placeholder used on displays with no physical notch — just
    /// enough to put the Panel somewhere sane. The Simulated Notch that gives
    /// such displays a real silhouette is its own issue.
    static let placeholderNotchWidth: CGFloat = 200

    let screenFrame: CGRect

    /// The camera notch's silhouette. The Panel leaves this rectangle empty in
    /// every state, so nothing is ever hidden under the camera.
    let notchRect: CGRect

    /// Whether `notchRect` describes real hardware or the stand-in.
    let hasPhysicalNotch: Bool

    init(screenFrame: CGRect, notchRect: CGRect, hasPhysicalNotch: Bool) {
        self.screenFrame = screenFrame
        self.notchRect = notchRect
        self.hasPhysicalNotch = hasPhysicalNotch
    }

    /// Derives the notch from the two areas a screen reports flanking it.
    ///
    /// Only the auxiliary areas' *sizes* are read, never their origins: the gap
    /// between them is placed against `screenFrame`, which keeps the result right
    /// whichever coordinate space AppKit hands those rectangles back in.
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
                x: screenFrame.midX - Self.placeholderNotchWidth / 2,
                y: screenFrame.maxY - height,
                width: Self.placeholderNotchWidth,
                height: height
            )
            self.hasPhysicalNotch = false
        }
    }

    /// The frame the Panel takes in `state`, flush with the top of the screen and
    /// centred on the notch.
    ///
    /// Snapped to whole points: a fractional origin lands the Panel's rounded
    /// corners on different subpixels each time it opens, which reads as a
    /// flickering edge.
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

    /// The notch's silhouette in the Panel's own coordinate space for `state`,
    /// origin top-left — the space SwiftUI lays content out in. This is the hole
    /// the content leaves in itself.
    func notchGap(for state: NotchPanelState) -> CGRect {
        CGRect(
            x: notchRect.minX - panelFrame(for: state).minX,
            y: 0,
            width: notchRect.width,
            height: notchRect.height
        )
    }

    /// How far the Panel reaches past the notch on each side in `state`.
    func flankWidth(for state: NotchPanelState) -> CGFloat {
        switch state {
        case .hidden: 0
        case .collapsed: Layout.collapsedFlank
        case .expanded: Layout.expandedFlank
        }
    }

    /// How far the Panel hangs below the strip in `state`.
    private func drop(for state: NotchPanelState) -> CGFloat {
        state == .expanded ? Layout.expandedDrop : 0
    }
}

extension NotchMetrics {
    /// Reads the geometry off a live display.
    @MainActor
    init(screen: NSScreen) {
        self.init(
            screenFrame: screen.frame,
            auxiliaryTopLeft: screen.auxiliaryTopLeftArea,
            auxiliaryTopRight: screen.auxiliaryTopRightArea,
            menuBarHeight: NSStatusBar.system.thickness
        )
    }
}
