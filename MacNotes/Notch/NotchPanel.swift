import AppKit

/// The window the Notch Panel is drawn in.
///
/// Borderless and non-activating, sitting above the menu bar so it can occupy
/// the strip around the camera. It never becomes key or main: whatever the user
/// is typing in keeps its focus.
final class NotchPanel: NSPanel {

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        // Above NSMainMenuWindowLevel and above the status items, so the notch
        // strip is ours rather than the menu bar's.
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 1)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        isMovableByWindowBackground = false
        // The Panel tracks the cursor itself, from the background — the only
        // place it ever covers when at rest is the camera housing, where macOS
        // draws nothing and puts nothing to click.
        acceptsMouseMovedEvents = true
        // Stay put when the app is not frontmost — which is nearly always.
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        // Follow the user across Spaces and over full-screen apps instead of
        // being left behind on the Space the panel was created on.
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// Cocoa keeps windows clear of the menu bar by default. The Notch Panel's
    /// whole job is to be in it, so the constraint is dropped.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}
