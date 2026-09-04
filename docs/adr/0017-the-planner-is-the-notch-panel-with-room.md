# The Planner is the Notch Panel with room

The Planner repeats the Notch Panel rather than complementing it. Today's Tasks, quick capture, the Allotted Time control and the button that starts a Focus Session all appear in both surfaces. The Planner adds the month, the Unscheduled, assigning Days, reordering and deleting; it takes nothing away.

## Considered Options

The glossary drew the line between them as present against planning: the Panel owns what is happening now, the Planner owns what happens later. It is the tidier model and it is the one this decision abandons, because it fails on the smallest sequence a user actually performs. Someone planning tomorrow in the Planner who decides to start on something now would have to close the window, find the notch, hover it and press a button they were already looking at. A boundary that makes the user change surfaces to act on the thing under their cursor is a boundary drawn for the model's benefit.

The duplication is real and it is the price. Two surfaces list a Task, so the row exists twice — the Planner's carrying a Day chip and a delete control the Panel's does not — and a change to how a Task reads has to be made in both.

What the split rests on now is presence rather than subject. The Notch Panel is always there and is read at a glance, and that is what bounds it: two Tasks visible, no deleting, no rescheduling, nothing whose accidental press costs anything the Panel cannot undo. The Planner is opened deliberately, and being opened deliberately is precisely what lets it carry the destructive controls ADR-0014 keeps off a surface that opens on hover.

## Consequences

Opening the Planner still returns the Notch Panel to `Hidden`, and that rule now carries weight it did not have when it was written. With both surfaces able to run a Session, it is the thing keeping one countdown on screen instead of two, and the Progress Tray out of a corner of the screen nobody is looking at.

Issue #9 grows by everything issue #8 builds. The row, the Allotted Time control and the capture field are worth building once and mounting twice; whether they end up shared or written out again is a question for whoever builds #9, not one this decides.
