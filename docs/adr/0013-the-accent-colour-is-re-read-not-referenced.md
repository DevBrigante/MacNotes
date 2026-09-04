# The accent colour is re-read, not merely referenced

The Progress Tray is stroked with a concrete colour, resolved from `NSColor.controlAccentColor` and read again whenever AppKit posts `NSColor.systemColorsDidChangeNotification`. It is not stroked with `Color(nsColor: .controlAccentColor)` and left to keep itself current. The control that starts a Focus Session takes the same colour through the same re-read, so that the button pressed and the line it sets growing are visibly the same thing.

## Considered Options

`NSColor.controlAccentColor` is a dynamic colour: it resolves, at draw time, to whatever the user has chosen in System Settings › Appearance. Handing it to SwiftUI as `Color(nsColor:)` therefore looks like it follows the setting for free, and that reading is half right. The colour would resolve correctly — if anything asked for it again. Nothing does. A SwiftUI view redraws when its state, its observed objects or its environment change, and the accent colour is none of those. The user picks a new accent, every menu and button on the machine turns, and the Tray stays the colour it was drawn.

So the change has to arrive as an invalidation, and `NSColor.systemColorsDidChangeNotification` is the public one AppKit posts for exactly this. Storing the *dynamic* colour in `@State` and reassigning it on the notification invalidates the view but leaves SwiftUI diffing one dynamic colour against the identical dynamic colour, with a redraw as the thing being decided — which is the bug again, one layer down. Resolving to sRGB at the moment it is read makes the stored value genuinely different, and the redraw follows from the value rather than from a guess about what SwiftUI will do with it.

## Consequences

The stored colour no longer varies with light and dark appearance, because it is resolved once per read rather than per draw. `controlAccentColor` differs a little between the two, and the Tray is a 2.5pt line on black chrome the app draws itself in both — the difference is not visible where this colour is used. Issue #11 puts the same accent on the Activity Graph, on the Planner's own background rather than on black; if the appearance variance matters anywhere it will matter there, and the re-read is the seam to hang it on.

No test asserts any of this. A notification can be posted in a test; the user changing their accent in System Settings, and every surface following, is a claim about AppKit that only a human at a real machine settles. #7 carries `needs-device-check` for it, and that check cannot happen until #8 gives the app a way to start a Focus Session at all — until then there is no Tray on screen to look at.
