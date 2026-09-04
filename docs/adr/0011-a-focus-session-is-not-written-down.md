# A Focus Session is not written down

The Focus Session lives in `FocusSessionModel` and nowhere else. Quitting MacNotes ends it. No `sessions.json` is written, and ADR-0002's file list should be read as `tasks.json` and `settings.json` — the third name was written before there was anything to put in it.

## Considered Options

A history of Sessions is the usual reason to persist them, and this app has no use for one. Issue #6 gives the previous Session no afterlife at all: starting one on another Task makes it disappear without a trace. Issue #11 counts completed Tasks for the Activity Graph, "not Focus Sessions, and never abandoned ones". Nothing in the app reads a Session that is over, so nothing has to keep it.

What is left worth persisting is a Session that is still running when the app goes away, and its value is smaller than it looks. Time passes while the app is gone, and a Session read back at launch has almost always run out during it, so the honest thing to do with it is end it — which is what starting with none does, without a file, a schema and a migration. In the minutes where it has not run out, restoring it means restoring a countdown the user did not watch. Completion is their explicit act, so nothing was lost by it either way.

The Session names its Task by `Task.ID` rather than holding a `Task`, which follows from the same reasoning. `TaskStore` owns the one copy of every Task and is the only thing that writes them down; a Session pointing into it cannot drift from it and cannot write through it. Issue #6 requires that ending a Session does not change its Task, and this is that requirement made structural rather than remembered.

## Consequences

Killing the app mid-Session loses it, and there is no recovery prompt to write. The cost is bounded by the durations on offer: at most an hour of a countdown nobody was looking at, and never a Task, a Note or a Completion — those go through `TaskStore`, which debounces to disk within a second (ADR-0002).

A surface showing the Session has to resolve the Task through the store to draw its title. That lookup is the price of the Session never being able to change it.
