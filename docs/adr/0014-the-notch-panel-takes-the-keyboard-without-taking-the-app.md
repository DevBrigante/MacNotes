# The Notch Panel takes the keyboard without taking the app

`NotchPanel.canBecomeKey` returns `true` and the panel keeps its `.nonactivatingPanel` style mask, so clicking the add field gives MacNotes the keyboard while the application the user was in stays frontmost. `NotchTrackingView` accepts the first mouse, so that click reaches the field instead of being spent making the window key. The Panel stays `Expanded` for as long as the field holds focus, whatever the cursor does, and hands the keyboard back by ordering itself out and straight back in as it leaves `Expanded`.

## Considered Options

Quick capture needs a text field, a text field needs a key window, and MacNotes has no window in the ordinary sense: it is an `.accessory` app whose only surface is a borderless panel that must never take the menu bar or the front application away from the user. `NSApp.activate` is the obvious way to get keystrokes and the wrong one — it makes MacNotes the active app and deactivates whatever the user was writing in, which is a large price for a two-word Task. `.nonactivatingPanel` is AppKit's answer to exactly this case: the panel receives keyboard input without its application activating. It was already in the style mask, put there so the Panel would not disturb anything on hover; `canBecomeKey` returning `false` was the other half of that promise, and it is also what made typing impossible.

Becoming key on hover would have been the smaller change and it is the worse one. The Panel opens on hover, a cursor crossing the notch on its way elsewhere opens it, and a Panel that took the keyboard each time would swallow keystrokes meant for the editor underneath. Key status is left to the click, which AppKit already routes to a panel willing to take it, and `acceptsFirstMouse` keeps that click from being consumed by the window taking key rather than landing on the field.

Holding `Expanded` while the field has focus is the other half of making capture usable. The Panel's state is otherwise a question about where the cursor is, and a cursor that drifts off while someone is still typing would collapse the Panel out from under the words. Focus is a second reason to stay open, so `NotchPanelModel` settles on `Expanded` when either the cursor is over the Panel or capture holds the keyboard.

Giving the keyboard back is what makes the arrangement safe. A key window that is no longer on screen — the Panel is `Hidden` inside the notch when nothing is running — would go on swallowing keystrokes with nothing to show for them. No API hands key status to another application, so the Panel orders itself out and immediately front again as it leaves `Expanded`: ordering out resigns key, ordering front puts the strip back where it was.

## Consequences

Almost none of this is testable. A test can assert that the panel is willing to become key and that the style mask still says `nonactivatingPanel`, and `NotchWindowControllerTests` does; whether the click lands on the field, whether the application the user was in keeps its front position, and whether the keyboard comes back when the Panel closes are claims about AppKit that only a human at a real machine settles. Issue #8 carries `needs-device-check`, and this is part of what that check covers.

The Panel is clickable now in a way it was not, which is what issue #8 asks for and also what a surface that opens on hover has to be careful about. Deleting is absent from it for that reason. Of the controls that are there, completing is the one an accidental press costs something: ADR-0007 leaves the store with no operation to reverse it, and the Planner is where that will have to be undone.
