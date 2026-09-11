import Foundation
import Observation
import ServiceManagement

nonisolated struct AppSettings: Codable, Equatable, Sendable {
    var sessionEndNotifications: Bool
    var showsProgressTray: Bool

    init(sessionEndNotifications: Bool = true, showsProgressTray: Bool = true) {
        self.sessionEndNotifications = sessionEndNotifications
        self.showsProgressTray = showsProgressTray
    }

    private enum CodingKeys: String, CodingKey {
        case sessionEndNotifications
        case showsProgressTray
    }

    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sessionEndNotifications = try values.decodeIfPresent(Bool.self, forKey: .sessionEndNotifications)
            ?? true
        showsProgressTray = try values.decodeIfPresent(Bool.self, forKey: .showsProgressTray) ?? true
    }
}

@MainActor
@Observable
final class SettingsStore {
    private(set) var preferences = AppSettings()
    private(set) var corruption: Corruption?
    private(set) var couldNotSave = false

    @ObservationIgnored private let file: JSONFile<AppSettings>

    init(file: JSONFile<AppSettings>) {
        self.file = file
    }

    convenience init() {
        self.init(file: JSONFile(name: "settings.json"))
    }

    func load(on today: Day) {
        preferences = AppSettings()
        corruption = nil

        switch file.read(on: today) {
        case .value(let stored):
            preferences = stored
        case .blank:
            break
        case .unreadable(let found):
            corruption = found
        }
    }

    func setSessionEndNotifications(_ enabled: Bool) {
        guard preferences.sessionEndNotifications != enabled else { return }
        preferences.sessionEndNotifications = enabled
        save()
    }

    func setProgressTrayShown(_ shown: Bool) {
        guard preferences.showsProgressTray != shown else { return }
        preferences.showsProgressTray = shown
        save()
    }

    func save() {
        do {
            try file.write(preferences)
            couldNotSave = false
        } catch {
            couldNotSave = true
        }
    }
}

enum LoginItemStatus: Equatable {
    case notRegistered
    case enabled
    case requiresApproval
}

@MainActor
protocol LoginItemService: AnyObject {
    var status: LoginItemStatus { get }

    func register() throws
    func unregister() throws
}

@MainActor
final class MainAppLoginItemService: LoginItemService {
    var status: LoginItemStatus {
        switch SMAppService.mainApp.status {
        case .enabled:
            .enabled
        case .requiresApproval:
            .requiresApproval
        case .notRegistered, .notFound:
            .notRegistered
        @unknown default:
            .notRegistered
        }
    }

    func register() throws {
        try SMAppService.mainApp.register()
    }

    func unregister() throws {
        try SMAppService.mainApp.unregister()
    }
}

@MainActor
@Observable
final class SettingsModel {
    private(set) var loginItemError: String?

    @ObservationIgnored private let store: SettingsStore
    @ObservationIgnored private let calendar: CalendarEvents
    @ObservationIgnored private let loginItem: any LoginItemService
    private var loginItemRevision = 0

    init(
        store: SettingsStore,
        calendar: CalendarEvents,
        loginItem: any LoginItemService
    ) {
        self.store = store
        self.calendar = calendar
        self.loginItem = loginItem
    }

    convenience init(store: SettingsStore, calendar: CalendarEvents) {
        self.init(store: store, calendar: calendar, loginItem: MainAppLoginItemService())
    }

    var launchesAtLogin: Bool {
        _ = loginItemRevision
        return loginItem.status == .enabled
    }

    var loginItemStatus: LoginItemStatus {
        _ = loginItemRevision
        return loginItem.status
    }

    var calendarAccess: CalendarAccess {
        calendar.access
    }

    var sessionEndNotifications: Bool {
        store.preferences.sessionEndNotifications
    }

    var showsProgressTray: Bool {
        store.preferences.showsProgressTray
    }

    func refresh() {
        loginItemRevision += 1
        calendar.refreshAccess()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try loginItem.register()
            } else {
                try loginItem.unregister()
            }
            loginItemError = nil
        } catch {
            loginItemError = error.localizedDescription
        }
        loginItemRevision += 1
    }

    func dismissLoginItemError() {
        loginItemError = nil
    }

    func setSessionEndNotifications(_ enabled: Bool) {
        store.setSessionEndNotifications(enabled)
    }

    func setProgressTrayShown(_ shown: Bool) {
        store.setProgressTrayShown(shown)
    }

    func connectCalendar() async {
        await calendar.connect()
    }

    func openCalendarSettings() {
        calendar.openSettings()
    }
}
