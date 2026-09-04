# The Planner shares the Task's verbs, not its card

ADR-0017 left one question to whoever built the Planner: whether the row, the Allotted Time control and the capture field are shared with the Notch Panel or written out again. They are written out again. What is shared is everything underneath them — `TaskStore` and `FocusSessionModel`, which between them hold every verb a Task has.

## Considered Options

The two rows look alike on paper: a circle that completes, a title, an Allotted Time chip, a control that starts a Session. Sharing them is the obvious move and the measurements are what argue against it. The Panel's card is 30pt tall, drawn in 11pt white on chrome the app paints black itself, sized so that two of them fit a strip hanging under the notch. The Planner's row is a `List` row in a window that follows light and dark, at system control sizes, carrying two controls the Panel refuses to have. A view parameterised over that much — height, palette, which controls exist — is not one card serving two surfaces; it is two cards with a switch down the middle, and the switch has to be read every time either surface changes.

The verbs are the opposite case. `complete`, `allot`, `move`, `give`, `note`, `delete` and `undoTheCompletion` are the same operations against the same file whichever surface presses them, and `Order` is one sequence across every Task precisely so that a drag in the Panel and a drag in the Planner are the same act. Those belong in one place and already had one. Only `startOrPause` had to move: it was four lines inside the Panel's card deciding whether a press starts a Session, pauses it or resumes it, and it is a question about the Session rather than about the card, so it is now `FocusSessionModel.startOrPause`.

Reordering is the sharpest illustration of the split. The Panel hand-rolls its drag — the cursor's grip on the card, the slot it lands in, the band at each edge that walks the list — because a strip above the menu bar has no `List` to lean on and because the Panel must stay `Expanded` for the length of the gesture. The Planner is a window, so `List` and `.onMove` do the whole gesture, and the only thing that crosses over is the index the drop lands on, handed to the same `TaskStore.move`. Two gestures, one sequence.

## Consequences

A change to what a Task row shows has to be made twice. ADR-0017 predicted that and priced it; this decision is where it is paid.

`Day` grew the calendar arithmetic both surfaces needed — `itsMonthInWeeks`, `monthStepped`, `stepped` — and the Activity Graph's own month layout was replaced by the shared one rather than left beside it. Calendar arithmetic is worth sharing for the same reason the verbs are: there is one right answer and it is testable away from any view.
