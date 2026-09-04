# The Notch Panel senses the cursor with a tracking area, not a global monitor

The Notch Panel opens when the cursor reaches it. The obvious way to notice that is `NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved)` — the app is never frontmost, so the cursor is always somewhere else. MacNotes uses an `NSTrackingArea` with `.activeAlways` on the Panel's own content view instead.

## Considered Options

Under the App Sandbox the global monitor is a trap: `addGlobalMonitorForEvents` returns a monitor object, logs nothing, denies nothing — and never delivers an event. Verified by building the same code twice, changing only `ENABLE_APP_SANDBOX`: hover worked unsandboxed and did nothing sandboxed.

A tracking area is not a workaround, it is the better mechanism. It costs no polling, sees only what happens over the Panel, and `.activeAlways` is what makes it work from the background — SwiftUI's `.onHover` and AppKit's default tracking options both stop at "while this app is active", which for MacNotes is never.

## Consequences

The Panel can only sense the cursor where it has a window. That fixes what each state's silhouette has to be, rather than leaving it to taste:

- `Hidden` is exactly the notch's silhouette. It draws nothing, but the window is there, and it is the only thing the user can aim at to open the Panel. It covers the camera housing alone — where macOS draws nothing and puts nothing to click — so blocking nothing is not a matter of care, it is a matter of geometry.
- `Collapsed` draws in the menu bar beside the notch. `Expanded` no longer merely covers that strip with a window while drawing below it — it fills the strip black and grows out of the notch as one surface, so for as long as the cursor is on it the middle of the menu bar is the Panel rather than the menu bar. Either way the clicks under them are ours, not the menu bar's. That strip is the app's surface; this is the cost of having one.

The sandbox stays on. It is not free, though: ADR-0002 puts the user's data in `~/Library/Application Support/MacNotes/` so that they can open, read and back it up, and a sandboxed app writing that path lands in its container instead. That conflict has to be settled when persistence is built, not here.
