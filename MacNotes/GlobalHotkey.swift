import Carbon

@MainActor
final class GlobalHotkey {
    private var reference: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private let action: @MainActor () -> Void

    init(action: @escaping @MainActor () -> Void) {
        self.action = action
        register()
    }

    deinit {
        if let reference { UnregisterEventHotKey(reference) }
        if let handler { RemoveEventHandler(handler) }
    }

    private func register() {
        var event = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        guard InstallEventHandler(
            GetApplicationEventTarget(), Self.respond, 1, &event,
            Unmanaged.passUnretained(self).toOpaque(), &handler
        ) == noErr
        else { return }

        let hotkey = EventHotKeyID(signature: 0x4D4E4F54, id: 1)
        guard RegisterEventHotKey(
            UInt32(kVK_Space), UInt32(cmdKey | shiftKey), hotkey,
            GetApplicationEventTarget(), 0, &reference
        ) == noErr
        else {
            if let handler { RemoveEventHandler(handler) }
            handler = nil
            return
        }
    }

    private static let respond: EventHandlerUPP = { _, _, pointer in
        guard let pointer else { return noErr }
        let hotkey = Unmanaged<GlobalHotkey>.fromOpaque(pointer).takeUnretainedValue()
        MainActor.assumeIsolated { hotkey.action() }
        return noErr
    }
}
