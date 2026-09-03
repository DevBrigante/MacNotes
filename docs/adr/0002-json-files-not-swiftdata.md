# Plain JSON files, not SwiftData

MacNotes persists everything as JSON under `~/Library/Application Support/MacNotes/`, split into `tasks.json`, `sessions.json` and `settings.json`. SwiftData is the obvious choice for a 2026 SwiftUI app and we are not using it.

## Considered Options

The data is one person's tasks — small enough that no storage engine's performance matters. What does matter is that the user can open the file, read it, back it up, and see for themselves that nothing leaves the machine. That is a stated goal of the project, and a store the user can't inspect undercuts it.

Splitting into three files is deliberate: a parse failure in one must not cost the other two. On a parse failure the app renames the file aside as `<name>.corrupt-<date>.json` and starts clean for that file only, surfacing it in the UI — never silently overwriting data it could not read. Writes are debounced ~1s after the last change, with a guaranteed save on `applicationWillTerminate`.

## Consequences

Schema migrations are hand-written. This is the real cost, and it is paid in full the first time the Task shape changes.
