import AppKit
import SwiftUI

@main
struct MacNotesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Settings {
            SettingsView(settings: delegate.settings)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let tasks = TaskStore(file: JSONFile(name: "tasks.json"))
    private let sessions = FocusSessionModel()
    private let settingsStore = SettingsStore()
    private let calendar = CalendarEvents()
    lazy var settings = SettingsModel(store: settingsStore, calendar: calendar)
    private lazy var sessionEndNotifications = SessionEndNotifications(settings: settingsStore)
    private var notch: NotchWindowController?
    private var planner: PlannerWindowController?
    private var hotkey: GlobalHotkey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        tasks.load(on: .today())
        settingsStore.load(on: .today())
        notch = NotchWindowController(tasks: tasks, sessions: sessions, settings: settingsStore)
        planner = PlannerWindowController(tasks: tasks, sessions: sessions, calendar: calendar)
        sessionEndNotifications.taskOpened = { [weak self] task in
            self?.planner?.close()
            self?.notch?.reveal(task)
        }
        sessions.sessionEnded = { [weak self] task in
            guard let self, let task = self.tasks.task(task) else { return }
            self.sessionEndNotifications.send(for: task)
        }
        hotkey = GlobalHotkey { [weak self] in
            guard let self else { return }
            self.sessions.respondToTheGlobalHotkey(with: self.tasks.tasks, on: .today())
        }
        showTheOneSurfaceAtATime()
        tasks.corruption.map(announce)
        settingsStore.corruption.map(announce)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        planner?.open()
        return true
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
        settingsStore.save()
    }

    private func showTheOneSurfaceAtATime() {
        notch?.plannerAsked = { [weak self] screen in self?.planner?.open(on: screen) }
        planner?.openChanged = { [weak self] isOpen in
            self?.notch?.model.plannerChanged(isOpen: isOpen)
        }
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
