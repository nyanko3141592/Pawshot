import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
            }

            Section("After Capture") {
                Toggle("Copy to clipboard", isOn: $settings.copyToClipboard)
                Toggle("Save to file", isOn: $settings.saveToFile)
                Toggle("Show floating preview", isOn: $settings.showFloatingPreview)
                Toggle("Play capture sound", isOn: $settings.playCaptureSound)
            }

            Section("Export") {
                Picker("Default format:", selection: $settings.exportFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.displayName).tag(format.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                if settings.selectedExportFormat == .jpg {
                    HStack {
                        Text("JPEG Quality:")
                        Slider(value: $settings.jpegQuality, in: 0.1...1.0, step: 0.05)
                        Text("\(Int(settings.jpegQuality * 100))%")
                            .monospacedDigit()
                            .frame(width: 40)
                    }
                }

                HStack {
                    Text("Save location:")
                    Text(settings.savePath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Choose...") {
                        chooseSaveLocation()
                    }
                }
            }

            Section("Window Capture") {
                Toggle("Include window shadow", isOn: $settings.captureWindowShadow)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func chooseSaveLocation() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            settings.savePath = url.path
        }
    }
}
