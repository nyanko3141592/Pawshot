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

            Section {
                Text("Shortcuts can be customized in a future update.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func labelForBinding(_ binding: HotkeyBinding) -> String {
        switch binding.id {
        case "captureFullScreen": return "Capture Full Screen"
        case "captureArea": return "Capture Area"
        case "captureWindow": return "Capture Window"
        default: return binding.id
        }
    }
}
