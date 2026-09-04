# The Panel paints black across the physical notch

`NotchPanelView` filled the notch region with `.clear` on a display that has a physical one, reasoning that a hole has no pixels to paint. It now fills it black in every state but `Hidden`, on every display, and the Panel stops caring which kind of notch it is drawing around.

## Considered Options

The reasoning was right about the hole and wrong about the rectangle it was applied to. `notchRect` is not a measurement of the camera housing — no API offers one. It is the gap between `auxiliaryTopLeftArea` and `auxiliaryTopRightArea`, the two regions AppKit reports as usable menu bar on either side. Those are layout areas, described so the system can place menus and status items clear of the housing, and where they are reported with clearance the gap between them is wider than the hole.

Whatever that clearance covers is lit screen. Filled with `.clear`, it is the desktop showing through: a bright seam down each side of the notch, turning one black pill into a title, a gap, and a countdown. The Panel looks broken in exactly the place its shape is supposed to be seamless, and the cause is invisible in the code, which reads as a considered decision not to waste paint on a hole.

Black costs nothing to be wrong about, in either direction. Inside the hole it is not displayed at all. Outside it, it is the colour the flanks are already filled with. That symmetry is the whole argument: the Panel does not have to know where the housing ends, and there is no API that would tell it.

## Consequences

`Hidden` still fills `.clear`, and that exception is load-bearing rather than an oversight. On the built-in display `Hidden` must leave the screen untouched — ADR-0003 makes that the reason the state can cover the camera housing without covering anything of the user's. Black over the clearance would put two thin bars in the menu bar with no Session on to justify them.

Hit testing over the region stays tied to `drawsItsOwnNotch`. The black is cosmetic where there is a hole behind it, and there is nothing there for a cursor to reach; over a Simulated Notch the Panel is the only thing drawn and takes its own clicks, as ADR-0004 already accounts for.

Whether the clearance exists at all, and how wide it is, is a claim about what AppKit reports on a notched Mac. It cannot be asserted in a test and it is the visible half of the defect this fixes, so issue #8 keeps `needs-device-check` for it.
