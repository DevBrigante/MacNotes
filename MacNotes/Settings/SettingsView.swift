import SwiftUI

struct SettingsView: View {
    @Bindable var settings: SettingsModel

    var body: some View {
        Form {
            Section("General") {
                Toggle(
                    "Launch at login",
                    isOn: Binding(
                        get: { settings.launchesAtLogin },
                        set: { settings.setLaunchAtLogin($0) }))
                loginItemState
            }
            Section("Calendar") {
                LabeledContent("Status", value: calendarState)
                calendarAction
            }
            Section("Focus Session") {
                Toggle(
                    "Session-end notification",
                    isOn: Binding(
                        get: { settings.sessionEndNotifications },
                        set: { settings.setSessionEndNotifications($0) }))
                Toggle(
                    "Progress Tray",
                    isOn: Binding(
                        get: { settings.showsProgressTray },
                        set: { settings.setProgressTrayShown($0) }))
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { settings.refresh() }
        .alert(
            "Launch at login could not be changed",
            isPresented: Binding(
                get: { settings.loginItemError != nil },
                set: { if $0 == false { settings.dismissLoginItemError() } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(settings.loginItemError ?? "")
        }
    }

    @ViewBuilder
    private var loginItemState: some View {
        switch settings.loginItemStatus {
        case .enabled:
            EmptyView()
        case .notRegistered:
            Text("MacNotes will not open automatically.")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .requiresApproval:
            Text("Finish approving MacNotes in System Settings.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var calendarState: String {
        switch settings.calendarAccess {
        case .notConnected:
            "Not connected"
        case .connected:
            "Connected"
        case .denied:
            "Access denied"
        case .unavailable:
            "Unavailable"
        }
    }

    @ViewBuilder
    private var calendarAction: some View {
        switch settings.calendarAccess {
        case .connected:
            EmptyView()
        case .denied:
            Button("Open System Settings", action: settings.openCalendarSettings)
        case .notConnected, .unavailable:
            Button("Connect Calendar") {
                Swift.Task { await settings.connectCalendar() }
            }
        }
    }
}
