import AppKit
import SwiftUI

@main
struct MacNotesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        // The Notch Panel is the app's surface, and it is not a window the user
        // opens — so there is no scene to show at launch. The Planner comes later.
        Settings {
            EmptyView()
        }
    }
}

/// The Notch Panel outlives every window, so the app delegate owns it.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var notch: NotchWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // No Dock icon and no menu bar of our own: MacNotes lives in the notch
        // strip and must never pull focus off whatever the user is working in.
        NSApp.setActivationPolicy(.accessory)
        notch = NotchWindowController()
    }
}
