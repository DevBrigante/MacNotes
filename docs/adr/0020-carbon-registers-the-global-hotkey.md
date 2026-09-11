# Carbon registers the global hotkey

MacNotes registers `Cmd+Shift+Space` with Carbon's `RegisterEventHotKey`. The registration reaches the app while another application is active and does not require Accessibility permission, unlike an AppKit global key-event monitor. `GlobalHotkey` owns the registration for the life of the app and turns the system event into one action; `FocusSessionModel` decides what that action means.

## Considered Options

`NSEvent.addGlobalMonitorForEvents` sounds like the direct AppKit fit, but macOS only delivers key events through it to a process trusted for Accessibility. Asking for that permission just to start a Focus Session makes a keystroke that should be immediately available depend on a security-sensitive setup step. A local event monitor has no such requirement and also cannot see the key while another application is active, which is the reason for this shortcut.

Carbon is old but its event hotkey registration remains the system interface for an application-owned key combination. It reserves the combination with macOS, leaves the front application alone, and calls MacNotes only when that precise combination is pressed. The registration can fail when another application already owns the combination; in that case MacNotes stays usable through the Notch Panel and Planner instead of intercepting unrelated input.

The callback's API boundary has no useful deterministic test seam: it is delivered by the running macOS event loop and depends on system-wide shortcut ownership. The behaviour on the other side is testable, so `FocusSessionModel.respondToTheGlobalHotkey(with:on:)` is the tested command boundary.

## Consequences

`Cmd+Shift+Space` is available from other applications without an Accessibility prompt. It can conflict with another app's registered hotkey, in which case no global shortcut is installed for this run.
