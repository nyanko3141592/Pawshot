import AppKit
import Carbon.HIToolbox

struct HotkeyBinding: Identifiable, Codable, Equatable {
    let id: String
    var keyCode: UInt32
    var modifiers: UInt32

    var displayString: String {
        var parts: [String] = []
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }

        let keyName: String
        switch Int(keyCode) {
        case kVK_ANSI_3: keyName = "3"
        case kVK_ANSI_4: keyName = "4"
        case kVK_ANSI_5: keyName = "5"
        default: keyName = "Key(\(keyCode))"
        }
        parts.append(keyName)
        return parts.joined()
    }
}

final class HotkeyService {
    static private(set) var sharedInstance: HotkeyService?

    static var currentBindings: [HotkeyBinding] {
        sharedInstance?.bindings ?? []
    }

    private var hotKeyRefs: [EventHotKeyRef?] = []
    private var handlerInstalled = false

    var bindings: [HotkeyBinding] = [
        HotkeyBinding(id: "captureFullScreen", keyCode: UInt32(kVK_ANSI_3), modifiers: UInt32(cmdKey | shiftKey)),
        HotkeyBinding(id: "captureArea", keyCode: UInt32(kVK_ANSI_4), modifiers: UInt32(cmdKey | shiftKey)),
        HotkeyBinding(id: "captureWindow", keyCode: UInt32(kVK_ANSI_5), modifiers: UInt32(cmdKey | shiftKey)),
    ]

    init() {
        HotkeyService.sharedInstance = self
        loadBindings()
    }

    func registerDefaults() {
        unregisterAll()

        if !handlerInstalled {
            installHandler()
            handlerInstalled = true
        }

        for (index, binding) in bindings.enumerated() {
            var hotKeyID = EventHotKeyID()
            hotKeyID.signature = OSType(0x50575354) // "PWST"
            hotKeyID.id = UInt32(index)

            var hotKeyRef: EventHotKeyRef?
            let status = RegisterEventHotKey(
                binding.keyCode,
                binding.modifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )

            if status == noErr {
                hotKeyRefs.append(hotKeyRef)
            } else {
                print("Failed to register hotkey: \(binding.id), status: \(status)")
                hotKeyRefs.append(nil)
            }
        }
    }

    private func unregisterAll() {
        for ref in hotKeyRefs {
            if let ref = ref {
                UnregisterEventHotKey(ref)
            }
        }
        hotKeyRefs.removeAll()
    }

    private func installHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            hotkeyCallback,
            1,
            &eventType,
            nil,
            nil
        )
    }

    func updateBinding(_ binding: HotkeyBinding) {
        if let index = bindings.firstIndex(where: { $0.id == binding.id }) {
            bindings[index] = binding
            saveBindings()
            registerDefaults()
        }
    }

    private func saveBindings() {
        if let data = try? JSONEncoder().encode(bindings) {
            UserDefaults.standard.set(data, forKey: "hotkeyBindings")
        }
    }

    private func loadBindings() {
        if let data = UserDefaults.standard.data(forKey: "hotkeyBindings"),
           let saved = try? JSONDecoder().decode([HotkeyBinding].self, from: data) {
            bindings = saved
        }
    }
}

// C-compatible function pointer for Carbon event handler
private func hotkeyCallback(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event = event else { return OSStatus(eventNotHandledErr) }

    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )

    guard status == noErr else { return OSStatus(eventNotHandledErr) }

    DispatchQueue.main.async {
        let coordinator = CaptureCoordinator.shared
        switch Int(hotKeyID.id) {
        case 0: coordinator.startCapture(mode: .fullScreen)
        case 1: coordinator.startCapture(mode: .area)
        case 2: coordinator.startCapture(mode: .window)
        default: break
        }
    }

    return noErr
}
