import AppKit
import SwiftUI

@main
struct MacNotesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let tasks = TaskStore(file: JSONFile(name: "tasks.json"))
    private var notch: NotchWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        tasks.load(on: .today())
        notch = NotchWindowController()
        tasks.corruption.map(announce)
    }

    func applicationWillTerminate(_ notification: Notification) {
        tasks.save()
    }

    private func announce(_ corruption: Corruption) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "MacNotes could not read \(corruption.file)"
        alert.informativeText = whatBecameOfIt(corruption)
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Show in Finder")

        NSApp.activate()
        guard alert.runModal() == .alertSecondButtonReturn else { return }
        NSWorkspace.shared.activateFileViewerSelecting([.macNotesStore])
    }

    private func whatBecameOfIt(_ corruption: Corruption) -> String {
        guard let setAside = corruption.setAside else {
            return """
                It was left exactly as it is, and MacNotes will not write to it until you move it \
                out of the way.
                """
        }
        return """
            It was kept as \(setAside) and MacNotes started that file over. Nothing else was \
            touched.
            """
    }
}
