# The store lives in the App Sandbox container

ADR-0002 says MacNotes keeps its three JSON files "under `~/Library/Application Support/MacNotes/`", and issue #5 repeats the path. The app is sandboxed, so on disk they land at `~/Library/Containers/com.devbrigante.macnotes/Data/Library/Application Support/MacNotes/`. The code asks `FileManager` for `.applicationSupportDirectory` and takes what it is handed: inside the sandbox that is the container, and the path ADR-0002 wrote down is the app's own view of the filesystem rather than the shell's.

## Considered Options

Spelling the path out by hand changes nothing. Under the sandbox `NSHomeDirectory()` is the container too, so `~/Library/Application Support/MacNotes` expands to the same place; reaching the real one means an absolute path the sandbox denies, and `ENABLE_USER_SELECTED_FILES` is `readonly`, so there is not even a file picker that could hand the app write access to it.

Turning the sandbox off would deliver the literal path. It would also spend a security boundary on a shorter string, and ADR-0003 already built the Notch Panel's only cursor sense around the sandbox being on — the app is not a good citizen of it by accident.

Taking the container keeps every promise ADR-0002 actually makes. The user can open the file, read it, back it up and see for themselves that nothing leaves the machine; all four hold at the longer path, which Finder's Go to Folder reaches like any other. What the ADR wanted was plain JSON the owner can inspect, not a particular directory.

## Consequences

The path in ADR-0002 and in issue #5 is where the app writes, said in the app's terms. Anyone looking for the files from a shell wants the container.

Deleting the container deletes the Tasks — "reset the app" is a real gesture and it is destructive. Time Machine backs the container up like the rest of `~/Library`.

Leaving the sandbox later would move the files, and the first launch after that would find none and start clean. That is a migration, and it is the second one this store owes; ADR-0002 already counted hand-written schema migrations as the price of the format.
