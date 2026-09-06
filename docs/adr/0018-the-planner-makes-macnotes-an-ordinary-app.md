# The Planner makes MacNotes an ordinary app while it is open

`PlannerWindowController` raises the activation policy to `.regular` as the window opens and drops it back to `.accessory` as it closes, and `applicationShouldHandleReopen` opens the Planner. MacNotes is an accessory app for as long as it is only a notch, and an ordinary one — Dock icon, menu bar, a place in ⌘-Tab — for as long as it has a window on screen.

## Considered Options

Staying `.accessory` was the first answer and it is the one that matches the app's character: MacNotes lives around the notch, and a Dock icon appearing and disappearing is a visible change of what the app is. It also very nearly works. A `.nonactivatingPanel` is not the only surface an accessory app may show; `NSApp.activate` brings an ordinary window forward, key equivalents still reach a main menu the app never displays, and typing into the Planner would have worked.

It fails on the way back. Opening the Planner returns the Notch Panel to `Hidden`, which is the rule that keeps one countdown on screen instead of two. `Hidden` on the built-in display draws nothing at all — there is no `⤢` to press, because there is no Panel. So the moment the user clicks another application, an accessory Planner is behind that window with nothing left anywhere on the machine that raises it again: not the Dock, which has no icon; not ⌘-Tab, which does not list accessory apps; not the notch, which is empty by the very rule that sent the user here. The window is reachable only by finding it under whatever is on top of it.

That is the whole argument. The rule "the Planner open means the Panel `Hidden`" is only safe if the Planner is reachable by ordinary means, and `.regular` is what makes it ordinary. The Dock icon that comes with it is not a side effect to be tolerated but the second half of the same decision — it is the thing the user presses when the window is buried, which is why `applicationShouldHandleReopen` opens the Planner rather than doing nothing.

## Consequences

The Dock icon and the menu bar appear when the window opens and go when it closes, and that flicker is the price. The menu bar is worth having on its own: ⌘W closes the window, ⌘Q quits, and the Edit menu carries the shortcuts a Notes field is expected to answer to.

The switch is a closure on the controller rather than a call inlined into `open()`, so `PlannerWindowControllerTests` can watch it happen without the test run stealing the front application from whoever is at the machine.

Nothing here is settled by a test. Whether the Dock icon arrives without a stutter, whether the notch really is empty behind the window, and whether closing the Planner gives the front application back are claims about AppKit that only a human at a real machine settles.
