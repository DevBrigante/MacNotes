# The domain's `Task` shadows Swift Concurrency's

`CONTEXT.md` calls the thing the user wants to get done a Task, and lists the words it refuses to call it instead. The type is `Task`, so inside the MacNotes module the bare name is the model. `Task { }` there does not start a concurrent job.

## Considered Options

Renaming the model gives the bare name back. `TodoItem`, `WorkItem`, `MacNotesTask` — each one is a synonym the glossary already rejects, adopted so the compiler is spared an ambiguity. The glossary exists so a term means the same thing in the code, the issues and the ADRs, and the first type to break it for convenience is the one that makes it optional.

Namespacing the other direction costs a prefix, `_Concurrency.Task`, and only where the module starts a job. There are none. `TaskStore` debounces its writes with a `Timer` added to the main run loop, which is what `NotchWindowController` already does for the cursor sampler, so the store introduces no idiom the app did not have.

## Consequences

Anything in this module that needs a concurrent job spells it `_Concurrency.Task`. Test files carry the shadowing too, through `@testable import MacNotes`.

`Timer` stays the app's way of doing something later. It is not a preference about structured concurrency — it is that the two places wanting a delay so far both live on the main actor and already had a run loop.
