# MacNotes

A personal macOS app that lives around the MacBook's camera notch. It holds the user's Tasks and runs a timer against one of them, so that what is being worked on right now is always visible without opening a window.

## Language

### Work

**Task**:
Something the user wants to get done. Carries a title, optionally Notes, and optionally the Day it belongs to.
_Avoid_: Todo, item, note, reminder

**Notes**:
Free text attached to a single Task, holding whatever context the Task needs. Not a standalone entity — Notes never exist without a Task.
_Avoid_: Description, observation, comment, body

**Day**:
The calendar date a Task belongs to. A Task carries a Day or nothing at all; it never carries a time of day.
_Avoid_: Date, due date, deadline, schedule

**Unscheduled**:
A Task with no Day. A Task whose Day has passed without it being completed becomes Unscheduled again, rather than carrying over or showing as overdue.
_Avoid_: Inbox, backlog, someday

**Completion**:
The Day a Task was finished on, and the only record that it was finished at all — a Task is done or not by whether it carries one. Always the user's explicit act, never something the app infers, and what exempts a Task from giving up a Day that has passed.
_Avoid_: Done flag, checked off, archived, closed

**Calendar Event**:
An event read from the user's macOS calendars through EventKit, shown alongside a Day for context. MacNotes only ever reads them, and nothing in the app depends on them — denying calendar access costs the user this view and nothing else.
_Avoid_: Meeting, appointment, commitment

**Focus Session**:
A stretch of time, whose duration the user chooses when starting it, dedicated to exactly one Task. Ending a Session does not change its Task; completion is always the user's explicit act. A Session lasts only as long as the machine is awake: a Mac that sleeps — lid closed or idle — ends it, and the next one is started from nothing.
_Avoid_: Timer, pomodoro, sprint, block

**Pause**:
Suspending a running Focus Session, leaving its remaining time untouched so resuming continues from that point. Only the user pauses — the app never infers an interruption, and a sleeping Mac ends a Session rather than pausing it — and a Session may be paused and resumed any number of times. Not a rest interval between Sessions; MacNotes has no such concept.
_Avoid_: Break, stop, interrupt

### Surface

**Notch Panel**:
The app's surface, drawn in the strip of screen around the camera notch, above the menu bar. The app's primary and permanent presence — not a window the user opens. Owns the present moment: today's Tasks, the running Session, and quick capture. It exists on one display at a time — the Active Display.
_Avoid_: Widget, HUD, overlay, island

**Active Display**:
The display the Notch Panel currently occupies: the one the cursor is on. The Panel follows the cursor across displays, taking a new one only once the cursor has rested there for about a second — so crossing a display on the way to a third never drags the Panel through it. A display that goes away hands the Panel on at once and without that wait, cursor or no cursor: a lid closed on an external monitor leaves one display, and the Panel takes it.
_Avoid_: Main screen, primary monitor, current screen

**Simulated Notch**:
The notch shape the Notch Panel draws for itself on a display that has no physical one, so that external monitors behave like the built-in screen. It occupies a strip and nothing else — content hangs below it, never covering what the user is looking at.
_Avoid_: Fake notch, virtual notch, pill

**Notch Marker**:
The dot drawn at the centre of a Simulated Notch while the Notch Panel is Hidden, and nowhere else. A physical notch tells the user where to aim by being a shape they can see; a display without one tells them nothing, and the Marker is what stands in for it. It goes the moment the Panel opens.
_Avoid_: Dot, indicator, badge, hint

**Progress Tray**:
The line tracing the Notch Panel's outline, growing from empty to full as a Focus Session runs. Drawn in the system accent colour, like the Activity Graph.
_Avoid_: Progress bar, timeline, ring

**Hidden**:
The Notch Panel's state when no Focus Session is running and the cursor is away, and whenever the Planner is open — drawn entirely within the notch's silhouette, physical or Simulated. Inside a physical notch that means nothing at all is drawn, and the display looks untouched; inside a Simulated one it means the Notch Marker and nothing else.

**Collapsed**:
The Notch Panel's state with a Focus Session running and the cursor away — the strip flanking the notch, showing the Session's remaining time and its Task.

**Expanded**:
The Notch Panel's state while the cursor is over it, revealing the fuller interface. Reachable from both Hidden and Collapsed.

**Planner**:
The app's window, opened from the Expanded Notch Panel. Owns planning rather than the present: the month, assigning Days, reorganising. Opening it returns the Notch Panel to Hidden.
_Avoid_: Main window, dashboard, settings

### Tracking

**Activity Graph**:
A grid of the current month, one cell per Day, shaded in proportion to how many Tasks the user completed that Day. Cells take their fill from the system accent colour and follow it when the user changes it in macOS settings.
_Avoid_: Heatmap, streak, stats, contributions
