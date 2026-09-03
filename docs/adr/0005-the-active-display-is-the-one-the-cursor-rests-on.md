# The Active Display is the one the cursor rests on, sampled four times a second

The Notch Panel exists on one display at a time. Until now that was `NSScreen.main`, a stand-in ADR-0004 already named as wrong: it follows the keyboard, and MacNotes is never the app holding it, so it points at whichever display the user's frontmost window happens to be on. The Active Display is now the display under the cursor, claimed once the cursor has rested there for a second, found by reading `NSEvent.mouseLocation` every 250ms.

## Considered Options

The cursor is the signal because it is the one the Panel is already built around. ADR-0003 makes the Panel's window the only thing the user can aim at to open it; the display they are working on is the display they are pointing at. Keyboard focus names a window, and for an app that never holds focus it names someone else's.

Reading the cursor by event was the first choice and is not available. ADR-0003 verified that `addGlobalMonitorForEvents` never delivers under the App Sandbox, which leaves the Panel one cursor sense: the tracking area on its own window, covering by construction the display it is already on. It can say when the cursor arrives at the Panel. It cannot say when the cursor has gone somewhere else entirely, and that is exactly the question here. Something has to ask.

That ADR's "costs no polling" is a claim about the tracking area, and it still holds where the tracking area applies. The poll it was preferred over was a poll on top of a clock this feature needs anyway: "the cursor has been here for a second" is not an event any API delivers, so even an event-driven version has to arm a timer on arrival and look again when it fires. One 4Hz tick answers both questions at once, and `NSEvent.mouseLocation` is a plain query of the current position rather than an event stream — nothing the sandbox has an opinion about.

The dwell is what makes the rule usable rather than a strobe. Displays are crossed to reach other displays, and without a delay the Panel would flash across every monitor between the one the cursor left and the one it is heading for. A second is long enough to outlast any crossing at pointer speed and short enough not to read as lag once the cursor settles. It is one constant, `ActiveDisplay.dwell`; the sampling interval is a quarter of it rather than a number of its own.

## Consequences

A migration lands between 1.00s and 1.25s after the cursor arrives, because the arrival the dwell is measured from is the first sample that saw it. The spec asks for ~1s and the sampling interval is the slack in it.

The dwell restarts whenever the cursor changes display, a return to the Active Display included. There and back never accumulates toward a migration, however long the two legs add up to.

The clock is `ProcessInfo.processInfo.systemUptime` and not `Date()`. A dwell measured against the wall clock would be lengthened or skipped outright by the user or by NTP moving it mid-migration.

Unplugging the Active Display leaves an id that matches no `NSScreen`. The Panel re-seats on the cursor's display immediately, with no dwell — there is no display left to pass through.

This closes the gap #25 left open: the Panel now comes back when the user does, because reaching a window on another display means putting the cursor there first. What it does not do is follow a display the user works on without pointing at — a second machine driving the keyboard, a window activated by a shortcut alone. Those are the cases `NSScreen.main` would have caught, and they are worth less than the pass-through the dwell kills.
