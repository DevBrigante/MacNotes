# Native SwiftUI, not Tauri

MacNotes draws its interface in the strip around the MacBook's camera notch, above the menu bar. We build it as a native macOS app in SwiftUI rather than in Tauri 2 with a React front end, which was the initial choice.

## Considered Options

Tauri was the natural pick on skill fit — the author writes React and Kotlin, and has never shipped Swift. It lost on where the project's risk sits. Every shipping notch app (boring.notch, NotchNook, Notchy, Alcove, mew-notch, DynamicNotch) is native SwiftUI; no Tauri or Electron precedent exists. Tauri creates a plain `NSWindow`, so occupying the notch strip means converting it to an `NSPanel` through the `tauri-nspanel` plugin's class swizzling and setting a window level above `NSMainMenuWindowLevel` by hand — untrodden ground, in the one part of the app that cannot be worked around if it fails.

The trade is deliberate: pay a new language across the whole app, to make the single highest-risk component a solved problem with five open-source implementations to read.
