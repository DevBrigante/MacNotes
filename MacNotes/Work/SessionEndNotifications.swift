import UserNotifications

@MainActor
final class SessionEndNotifications: NSObject, UNUserNotificationCenterDelegate {
    var taskOpened: (@MainActor (Task.ID) -> Void)?

    private let settings: SettingsStore
    private let center: UNUserNotificationCenter

    init(settings: SettingsStore, center: UNUserNotificationCenter = .current()) {
        self.settings = settings
        self.center = center
        super.init()
        center.delegate = self
    }

    func send(for task: Task) {
        guard settings.preferences.sessionEndNotifications else { return }

        Swift.Task { [weak self] in
            guard let self,
                try await center.requestAuthorization(options: [.alert]),
                settings.preferences.sessionEndNotifications
            else { return }
            deliver(task)
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        guard let identifier = UUID(uuidString: response.notification.request.content.userInfo["task"] as? String ?? "") else {
            completionHandler()
            return
        }

        Swift.Task { @MainActor [weak self] in
            self?.taskOpened?(identifier)
            completionHandler()
        }
    }

    private func deliver(_ task: Task) {
        let content = UNMutableNotificationContent()
        content.title = "Focus Session ended"
        content.body = task.title
        content.userInfo = ["task": task.id.uuidString]

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request)
    }
}
