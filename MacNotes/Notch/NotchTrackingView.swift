import AppKit

final class NotchTrackingView: NSView {
    var cursorIsOver: ((Bool) -> Void)?

    private var area: NSTrackingArea?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        guard area == nil else { return }

        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        )
        addTrackingArea(area)
        self.area = area
    }

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
