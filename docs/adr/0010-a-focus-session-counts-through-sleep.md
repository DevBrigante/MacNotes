# A Focus Session's clock keeps counting while the Mac sleeps

`FocusSession` is told the time rather than reading it: `remaining(at:)`, `pause(at:)` and `resume(at:)` all take a `TimeInterval` on a monotonic scale. The scale the app supplies is `ContinuousClock`, measured from an origin captured the first time `FocusSession.now` is read.

## Considered Options

`Date()` is the obvious clock and the wrong one for the same reason ADR-0005 rejected it for the dwell. The user and NTP both move the wall clock, and a Session measured against it gains or loses exactly as much time as the correction. Issue #6 asks that pause and resume neither lose nor gain time; a clock that can jump backwards makes that promise unkeepable in a way no amount of care in the model can fix.

`ProcessInfo.processInfo.systemUptime` is the clock ADR-0005 chose, and reusing it would have left the app with one. It counts the time the machine has been awake, so it stops while the Mac sleeps. Over the dwell's one second that difference cannot be observed. Over a 25-minute countdown it is the whole question: close the lid, open it an hour later, and a Session on that clock picks up where it left off, having decided on the user's behalf that shutting the lid was a Pause. Issue #6 is explicit that the app never infers an interruption, and `CONTEXT.md` says only the user pauses. A Session that quietly suspends itself is the app doing exactly what both forbid.

`ContinuousClock` is the one clock that is both monotonic and unbroken by sleep, which is what makes it right here: time that passed is time that passed, and the only thing that stops the count is the user asking for it.

## Consequences

The app now keeps two clocks, and they disagree by however long the Mac has slept. That is not a wart to tidy away later: `ActiveDisplay`'s dwell asks how long the cursor has been somewhere, which is a question about a machine that is awake, and a Focus Session asks how much of an hour is left, which is not.

Waking to a Session that ran out during sleep is the ordinary case. Nothing had to be done for it — the countdown reads the clock on its next tick, finds nothing remaining, and ends the Session as it would have with the lid open.

`FocusSession.now` counts from an arbitrary origin inside one launch and means nothing outside it. Nothing is stored against it, which ADR-0011 makes a rule rather than an oversight.
