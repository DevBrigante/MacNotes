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

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        tasks.save()
        guard tasks.couldNotSave else { return .terminateNow }

        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "MacNotes could not save your Tasks"
        alert.informativeText = """
            Everything since the last save is still only in memory, and quitting now loses it.
            """
        alert.addButton(withTitle: "Quit Anyway")
        alert.addButton(withTitle: "Stay Open")

        NSApp.activate()
        return alert.runModal() == .alertFirstButtonReturn ? .terminateNow : .terminateCancel
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
                It was left exactly as it is, and MacNotes cannot write that file until you move \
                it out of the way yourself.
                """
        }
        return """
            It was kept as \(setAside) and MacNotes started that file over. Nothing else was \
            touched.
            """
    }
}
