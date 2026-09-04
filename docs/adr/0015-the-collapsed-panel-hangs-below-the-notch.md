# The Collapsed Panel hangs below the notch so the Progress Tray is one line

`Collapsed` is no longer the menu bar strip and nothing more. It hangs ten points below the notch's bottom edge, and the Progress Tray it carries is the single unbroken sweep ADR-0012 rejected: down the left side, along the bottom, up the right. That ADR is superseded.

## Considered Options

ADR-0012 did not prefer two mirrored halves. It chose them because the geometry left nothing else: with `drop` at zero the Panel's bottom edge *was* the notch's bottom edge, a line traced along it crossed the camera housing where no pixels exist, and the result was two stubs with a hole between them. The reasoning was sound and it was a reasoning about a silhouette, not about taste — so changing the silhouette is what reopens it.

Ten points is not a round number chosen for comfort. The Tray is stroked 2.5pt wide, inset 5pt from the Panel's edge, on a corner radius of 10 that the inset leaves at 5. A drop shorter than inset plus radius gives the bottom corners no room to curve and the sweep comes out with its corners shaved flat — the exact failure ADR-0012 records the reference app hitting from the other direction. Ten clears it with nothing to spare, which is the point: every point of it is paid for out of the user's window.

That payment is what ADR-0012 refused, in these words: it "costs the thing Collapsed is for — a Session visible without anything hanging into the user's window". The refusal held while the only thing on offer was a line's shape. It stops holding once the Panel is read as one object: a Session's progress that vanishes for two hundred points in the middle and reappears travelling the other way is the one thing on screen the user reads without looking at, and it should not need explaining.

A different shape per display was the obvious way to pay less — an external monitor has no camera to protect, so it could keep `drop` at zero and sweep unbroken across a Simulated Notch that is pure drawing. It is rejected because the Panel follows the cursor across displays after a dwell (ADR-0005). A Session begun on the built-in screen and continued on an external one would change the shape of its own progress indicator halfway through the count, and an indicator that redraws itself while it is being read is worse than either shape.

## Consequences

The Collapsed Panel covers roughly 344 by 10 points of whatever is beneath it, centred, for the length of every Session. On the built-in display that is 10pt of a maximised window's chrome; on an external monitor it is 10pt below a menu bar that already reserved its own strip.

`Hidden` keeps its drop at zero and is untouched. It has to stay exactly the notch's silhouette or it stops being invisible on the built-in screen, and ADR-0003 makes that silhouette the only thing the cursor can aim at to open the Panel at all.

`Expanded` already traced an unbroken outline below the strip, so it needs nothing from this. What changes is that the two states now trace the same shape for the same reason, and the Tray's rule collapses to one sentence: it follows the edge of the black the Panel is drawing.
