import AppKit

/// Reports the cursor arriving on and leaving the Notch Panel.
///
/// SwiftUI's `.onHover` — and any tracking area left on its default options —
/// only tracks while its own app is active, and MacNotes never is. So the
/// tracking area is installed by hand, with `.activeAlways`.
final class NotchTrackingView: NSView {

    /// Called with `true` when the cursor arrives on the Panel, `false` when it leaves.
    var cursorIsOver: ((Bool) -> Void)?

    private var area: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        // Installed once and left alone. `inVisibleRect` keeps it on the bounds
        // as the Panel resizes, and rebuilding it here would fire a spurious
        // exit on every frame of the resize — with the cursor still on the
        // Panel, which reads as a flicker between Expanded and rest.
        guard area == nil else { return }

        let area = NSTrackingArea(
            rect: .zero,  // ignored under `inVisibleRect`
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        )
        addTrackingArea(area)
        self.area = area
    }

    // Both events mean the same thing here: look again. Resizing the Panel
    // makes AppKit fire enter and exit in pairs while the cursor has not moved
    // at all — an exit arrives with the cursor still on the Panel, an enter with
    // the cursor a screenful away. Taking either at face value flickers the
    // Panel between Expanded and rest. The cursor's own position is the answer.

    override func mouseEntered(with event: NSEvent) {
        reportWhereTheCursorReallyIs()
    }

    override func mouseExited(with event: NSEvent) {
        reportWhereTheCursorReallyIs()
    }

    private func reportWhereTheCursorReallyIs() {
        guard let window else { return }
        cursorIsOver?(window.frame.contains(NSEvent.mouseLocation))
    }
}
