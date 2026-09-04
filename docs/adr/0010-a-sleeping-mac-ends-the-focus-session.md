# A sleeping Mac ends the Focus Session; a lid closed on an external display does not

`FocusSessionModel` watches `NSWorkspace.willSleepNotification` and ends the Session when it arrives. Nothing else about sleep is special-cased, and the clock it counts on is `ContinuousClock`, read through `FocusSession.now`.

## Considered Options

A closed lid is two different events and the app cannot see the lid. Closed on a MacBook driving an external display, the Mac never sleeps: the work carries on over there, and the Notch Panel goes with it — the built-in screen leaves `NSScreen.screens`, which is the case ADR-0005 already handles by re-seating the Panel on the only display left, at once and with no dwell, because there is no display to pass through. Closed on a MacBook alone, the Mac sleeps, and nothing is happening at all. `willSleepNotification` separates the two exactly, without asking about lids or counting displays.

Ending is what the second case deserves, and Pausing is the tempting wrong answer. A paused Session is waiting to be resumed: it holds a Task on screen, keeps its remaining time, and asks the user returning hours later to remember what they had been doing when they shut the machine. Ending asks nothing, and starting again is one press on a Session whose duration the user picks fresh. This is not the app inferring an interruption — issue #6 forbids idle detection and app-switch detection, both of which are guesses about attention on a running machine. A Mac that has suspended is not a guess. Nor is it a Pause, so `CONTEXT.md`'s "only the user pauses" survives intact.

Letting the Session count through sleep and simply expire was the previous decision here, and it makes the rule depend on how long the lid was down. An hour's sleep over a 25-minute Session lands in the same place either way. A three-minute one hands back a Session mid-count that nobody was in, which is the thing worth avoiding.

The clock survives the change with its reasons rearranged. `Date()` is out for the reason ADR-0005 gives for the dwell: the user and NTP both move the wall clock, and a Session measured against it gains or loses exactly the correction, which makes issue #6's "pause and resume must not lose or gain time" unkeepable. `ProcessInfo.processInfo.systemUptime` — ADR-0005's choice — stops while the Mac sleeps, and with sleep ending the Session that difference should now never be observed. `ContinuousClock` stays anyway because *should never* is doing work in that sentence: `willSleepNotification` is the app being told, and if it is ever not told, the continuous clock leaves a surviving Session reading the honest time and expiring on its next tick, where `systemUptime` would resume it as though the hour had not happened.

## Consequences

Clamshell cannot be tested. No test closes a lid, unplugs a display, or suspends a machine, so the whole first paragraph is a claim a human has to check on a real MacBook and a real external monitor. Issue #6 carries `needs-device-check` for it.

Tasks and Notes are untouched by any of this. Sleep preserves memory rather than ending the process, so `TaskStore`'s debounced write is still pending on wake and lands a second later, and `applicationWillTerminate` is not involved. Only the countdown is lost, which is what the rule is about.

Display sleep is not system sleep. A screen that darkens on idle posts nothing this model listens to, and a Session runs on underneath it.

The app keeps two clocks, and they disagree by however long the Mac has slept. `ActiveDisplay`'s dwell asks how long the cursor has been somewhere, which is a question about a machine that is awake; a Focus Session asks how much of an hour is left, which is not.
