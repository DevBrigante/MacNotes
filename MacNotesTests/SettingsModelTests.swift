import Foundation
import Testing

@testable import MacNotes

@MainActor
final class SettingsModelTests {
    private let folder = TemporaryFolder()
    private let loginItem = LoginItemServiceStub()
    private let calendarSource = SettingsCalendarSourceStub()
    private let store: SettingsStore
    private let model: SettingsModel

    init() {
        store = SettingsStore(file: JSONFile(name: "settings.json", in: folder.url))
        model = SettingsModel(
            store: store,
            calendar: CalendarEvents(source: calendarSource),
            loginItem: loginItem)
    }

    deinit {
        folder.discard()
    }

    @Test func launchAtLoginReadsTheServicesCurrentStatus() {
        loginItem.status = .enabled

        #expect(model.launchesAtLogin)

        loginItem.status = .notRegistered

        #expect(model.launchesAtLogin == false)
    }

    @Test func changingLaunchAtLoginRegistersOrUnregistersTheService() {
        model.setLaunchAtLogin(true)
        model.setLaunchAtLogin(false)

        #expect(loginItem.registerCount == 1)
        #expect(loginItem.unregisterCount == 1)
    }

    @Test func refreshReadsTheCalendarsCurrentPermission() {
        calendarSource.access = .denied

        model.refresh()

        #expect(model.calendarAccess == .denied)
    }

    @Test func focusPreferencesAreSavedAsTheyChange() {
        model.setSessionEndNotifications(false)
        model.setProgressTrayShown(false)

        let file = JSONFile<AppSettings>(name: "settings.json", in: folder.url)

        #expect(
            file.read(on: Day(year: 2026, month: 9, day: 10))
                == .value(AppSettings(sessionEndNotifications: false, showsProgressTray: false)))
    }
}

@MainActor
private final class LoginItemServiceStub: LoginItemService {
    var status: LoginItemStatus = .notRegistered
    private(set) var registerCount = 0
    private(set) var unregisterCount = 0

    func register() throws {
        registerCount += 1
        status = .enabled
    }

    func unregister() throws {
        unregisterCount += 1
        status = .notRegistered
    }
}

@MainActor
private final class SettingsCalendarSourceStub: CalendarEventSource {
    var access: CalendarAccess = .notConnected

    func requestAccess() async throws {
        access = .connected
    }

    func events(on day: Day) -> [CalendarEvent] {
        []
    }

    func openSettings() {}
}
