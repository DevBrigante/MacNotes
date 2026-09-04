# A write that cannot land is announced, not swallowed

`TaskStore.save()` reports failure. It does not check first whether writing is allowed, and it does not drop the error on the floor. Nothing in the store guards `tasks.json` against being overwritten while a file it could not read is still sitting there.

## Considered Options

The guard was written first and looked obligatory: issue #5 says never silently overwrite data that could not be read, so if `JSONFile` cannot move the unreadable file aside, the store should refuse to write over it. It cost a latch — one flag, set at load, never lifted — and the latch is what made it wrong. The store went on accepting Tasks all session, dropped every debounced write, dropped the save on quit, and told the user nothing after the alert at launch. It traded a loss the spec forbids for a bigger one of the same kind.

The guard was also redundant. Moving the file and replacing it need the same permission on the same directory, and an atomic write *is* a rename: where `moveItem` is refused, `write(options: .atomic)` is refused too, and the bytes survive because the filesystem said no. `MacNotesTests.neverOverwritesAFileItCouldNotSetAside` asserts the outcome the spec asks for, and it passes with nothing in the store enforcing it.

What remained was the gap the guard was papering over. `try?` around the write turned every failure — a full disk, a locked folder, a file someone else holds — into silence. It is now a `do`/`catch` that sets `couldNotSave`, and `applicationShouldTerminate` reads it: quitting with work that never reached disk asks first, and the user can stay open and go fix it.

The name search behind the set-aside lost its cap of 99 attempts for the same reason. A bound means the search can give up while the disk is perfectly healthy, and the caller cannot tell that apart from a filesystem that refused. It now walks `-2`, `-3`, … until a free name turns up, so `setAside == nil` means one thing.

## Consequences

Two hooks save on the way out. `applicationShouldTerminate` writes and then asks if the write failed; `applicationWillTerminate` is the guaranteed save issue #5 names, and running twice costs one redundant encode of a list that is already in memory.

`couldNotSave` is observable and nothing observes it during a session yet. A save that fails at 10am is not seen until quit, and the Notch Panel is the place that will show it once #8 gives it a surface.

Neither hook is called when the app is killed outright. The debounce is what covers that, and the second it waits is the most that can be lost.
