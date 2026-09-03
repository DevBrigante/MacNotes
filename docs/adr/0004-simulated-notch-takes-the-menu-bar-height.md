# The Simulated Notch takes the menu bar's height, not the physical notch's

On a display with no camera housing, the Notch Panel draws its own notch — the Simulated Notch — so that external monitors behave like the built-in screen. It copies the shape and the width. It does not copy the height: it is as tall as the menu bar on the display it is drawn on.

## Considered Options

The obvious reading of "the same silhouette" is the same rectangle: 200pt wide and ~37pt tall, the strip a notched MacBook reserves. An external monitor's menu bar is ~24pt. Copying the 37 would hang 13pt of black below the menu bar, over the top of whatever window the user has up there — the one thing the Notch Panel must never do. The width stays a fixed 200pt for the opposite reason: nothing sits behind it to match, so it can be the same everywhere, and a shape that resized per monitor would make the Panel's layout a function of the display.

The height is measured per display as `frame.maxY - visibleFrame.maxY` rather than read from `NSStatusBar.system.thickness`, which reports one number for the whole system. That difference is zero on a display that reserves nothing at the top — a secondary display with no menu bar of its own, "Displays have separate Spaces" turned off, or a menu bar set to hide automatically — and there the fallback is the system thickness. The Panel still needs a strip to live in, and the top of the display is the only place it can be, so on those displays `Collapsed` and `Expanded` do draw over the top ~24pt of whatever is up there. ADR-0003 already took that trade for the menu bar; this extends it to displays that have no menu bar to trade.

## Consequences

`Hidden` on such a display draws one thing and one thing only: the Notch Marker, a dot at the centre of the silhouette.

Drawing nothing at all was the first answer, and it lasted exactly one session on a real external monitor. The reasoning was sound and incomplete. On the built-in screen `Hidden` hides inside black the hardware is already drawing, so drawing nothing leaves the display untouched — true, and it misses that the same black is also the only thing telling the user where to aim. Take the hardware away and `Hidden` is a 200×24 invisible target somewhere in a menu bar, and the user hunts for it. The Simulated Notch exists to make an external display behave like the built-in one; a shape nobody can find is not that. The Marker costs a dot on a display that was otherwise clean and buys back the parity the whole thing is for.

The window is there either way, exactly the notch's silhouette — ADR-0003 makes it the only thing the cursor can aim at to open the Panel.

Present has a price the physical notch does not pay. ADR-0003 could say `Hidden` blocks nothing because the silhouette covers the camera housing, "where macOS draws nothing and puts nothing to click". A Simulated Notch covers 200pt of a live menu bar instead, and swallows the clicks that land there. Making the window click-through would cost the tracking area its events, and with it the only way to open the Panel under the App Sandbox — so the dead strip stays. It sits mid-menu-bar, between the app menus and the status items, where there is usually nothing to hit, and the Marker narrows the surprise without closing it: 6pt say something is here, 200pt eat the click.

Reaching any of this needed one more change: the Panel used to pick `NSScreen.screens.first { $0.auxiliaryTopLeftArea != nil }`, pinning itself to the built-in display and making the Simulated Notch unreachable on the machine most likely to need it. It now takes `NSScreen.main`, which is a stand-in and not the Active Display: it follows the keyboard, and MacNotes is never the app holding it, so it names whichever display the user's frontmost window is on. Close enough to demonstrate the Simulated Notch, and wrong often enough that the Active Display gets its own rule — the cursor dwell — in its own issue.
