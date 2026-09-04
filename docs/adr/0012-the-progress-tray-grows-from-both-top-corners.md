# The Progress Tray grows from both top corners and stops at the notch

The Progress Tray is not one line swept once around the Notch Panel's outline. It is two mirrored halves, each starting at a top corner, running down its side, around the bottom corner and inward, both growing together as the Focus Session runs. Neither half reaches the notch.

## Considered Options

The obvious shape is the reference app's: one open-top rounded frame, trimmed from zero to the elapsed fraction, sweeping down the left side, along the bottom and up the right. It works there because the collapsed pill hangs *below* the notch — its bottom edge is on glass the whole way across.

MacNotes' Collapsed Panel is the menu bar strip and nothing more: `drop` is zero, so the Panel is exactly `notchRect.height` tall and its bottom edge *is* the notch's bottom edge. A line traced along it crosses the camera housing, where there are no pixels — it would come out as two stubs on the flanks with a hole between them, and it would break the rule ADR-0003 states as geometry rather than care: the Panel draws nothing over the camera. Making the Panel taller to buy a clear bottom edge is the other way out, and it costs the thing Collapsed is for — a Session visible without anything hanging into the user's window.

Two halves take the interruption as the premise instead of fighting it. Each traces the flank it lives on and stops five points short of the notch, so the camera is never drawn on and never has to be. The growth reads as the notch filling in from both sides at once, which is what the shape asks for, and it is symmetric like everything else the Panel draws. A single sweep across two subpaths was the cheaper version of the same geometry, and it grows through a jump: the line finishes the left flank, disappears, and reappears at the notch's right edge travelling outward. The Tray is the one thing on screen the user reads at a glance; it should not need explaining.

The Simulated Notch is interrupted the same way even though nothing is behind it to protect. ADR-0004 exists so that external monitors behave like the built-in screen, and a Tray that ran unbroken on one and not on the other would undo that for the sake of two hundred points of line.

## Consequences

Both halves carry the same fraction, so the Tray reads as one thing with a gap, not as two indicators. The full length a half traces is a function of the flank, so the same fraction covers slightly different distances on a display whose menu bar is shorter than a physical notch — the Tray is a proportion of a Session, not a ruler.

Expanded leaves the whole menu bar strip alone, so there is no outline up there to trace: the Tray drops with the Panel and traces the body below the strip, meeting in the middle at the bottom rather than at a notch. One rule covers both — the Tray traces the black the Panel is drawing.

It is drawn as an overlay on the Panel-sized frame, outside the flanks' own fills. The reference app learned this the hard way and fixed it in a commit of its own: run the tray through the pill's clip and the clip shaves its rounded corners flat, however the radius is tuned. MacNotes fills the flanks rather than clipping to them, so the trap is not live here — but the Tray sits outside them anyway, because the alternative is to rediscover it the next time the Panel's chrome changes.
