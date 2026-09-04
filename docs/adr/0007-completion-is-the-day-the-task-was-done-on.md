# Completion is the Day the Task was done on

`Task` carries `completedOn: Day?`. Done or not done is `completedOn != nil`, and there is no separate flag.

## Considered Options

Issue #5 lists the model as "title, optional `Notes`, optional `Day`, completion", and the smallest thing that reads is a `Bool`. It answers the only question the Notch Panel asks — is this done — and nothing else.

The Activity Graph asks a different one: how many Tasks the user completed on a given Day. A boolean cannot answer it, and the nearest substitute, the Task's own `Day`, is wrong twice over. A Task that was Unscheduled when it got finished has no `Day` at all and would never reach a cell. A Task finished a day early, or finished today after its Day passed, would shade the day it was planned for instead of the day the work happened. The graph is a record of what the user did, so it is keyed on when they did it.

Carrying both — a flag and a date beside it — makes two fields that can disagree: completed with no date, a date with the flag off, and every screen deciding which one it believes. One optional cannot contradict itself.

The passed-Day rule reads completion as well: a Task whose Day has passed *without being completed* becomes Unscheduled. `isCompleted` falls out of the optional, so the rule costs nothing extra.

## Consequences

`completedOn` and `day` move independently. Completing a Task does not give it a Day, and scheduling one does not touch its completion. A Task completed on a Day that has since passed keeps that Day — the passed-Day rule only takes a Day away from work that never got done, which is what makes the graph's history stable.

Nothing un-completes a Task. Issue #8 lists completing and no reverse, so the store has no operation for it; when a screen wants one it is `completedOn = nil` and the same `update`.
