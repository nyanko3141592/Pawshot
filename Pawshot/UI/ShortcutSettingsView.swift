import SwiftUI

struct ShortcutSettingsView: View {
    private var bindings: [HotkeyBinding] {
        HotkeyService.currentBindings
    }

    var body: some View {
        Form {
            Section("Capture Shortcuts") {
                ForEach(bindings) { binding in
                    HStack {
                        Text(labelForBinding(binding))
                        Spacer()
                        Text(binding.displayString)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(6)
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }

            Section("macOS System Shortcuts") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pawshot uses the same shortcuts as macOS built-in screenshot (⌘⇧3/4/5). To avoid conflicts, disable the system shortcuts:")
                        .font(.callout)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("1. Open **System Settings** → **Keyboard** → **Keyboard Shortcuts**")
                        Text("2. Select **Screenshots** in the sidebar")
                        Text("3. Uncheck the shortcuts that conflict")
                    }
                    .font(.callout)

                    Button("Open Keyboard Shortcuts Settings") {
                        openKeyboardShortcutsSettings()
                    }
                }
            }

            Section {
                Text("Custom shortcut recording will be available in a future update.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func openKeyboardShortcutsSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension?Shortcuts") {
            NSWorkspace.shared.open(url)
        }
    }

    private func labelForBinding(_ binding: HotkeyBinding) -> String {
        switch binding.id {
        case "captureFullScreen": return "Capture Full Screen"
        case "captureArea": return "Capture Area"
        case "captureWindow": return "Capture Window"
        case "ocrText": return "OCR Text"
        default: return binding.id
        }
    }
}
