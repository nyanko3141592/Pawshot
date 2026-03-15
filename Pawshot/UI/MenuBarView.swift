import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var coordinator: CaptureCoordinator

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("Pawshot")
                    .font(.headline)
                    .padding(.top, 8)

                Divider()
                    .padding(.vertical, 4)
            }

            VStack(spacing: 2) {
                ForEach(CaptureMode.captureModes) { mode in
                    captureButton(mode: mode)
                }

                Divider()
                    .padding(.vertical, 4)

                captureButton(mode: .ocrText)
            }

            Divider()
                .padding(.vertical, 4)

            VStack(spacing: 2) {
                Button {
                    if let screenshot = coordinator.lastScreenshot {
                        coordinator.openEditor(for: screenshot)
                    }
                } label: {
                    HStack {
                        Image(systemName: "pencil.and.outline")
                            .frame(width: 20)
                        Text("Edit Last Screenshot")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .disabled(coordinator.lastScreenshot == nil)

                Button {
                    if #available(macOS 14.0, *) {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    } else {
                        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                    }
                } label: {
                    HStack {
                        Image(systemName: "gear")
                            .frame(width: 20)
                        Text("Settings...")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }

            Divider()
                .padding(.vertical, 4)

            Button {
                NSApp.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "power")
                        .frame(width: 20)
                    Text("Quit Pawshot")
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .padding(.bottom, 4)
        }
        .frame(width: 240)
    }

    private func captureButton(mode: CaptureMode) -> some View {
        Button {
            coordinator.startCapture(mode: mode)
        } label: {
            HStack {
                Image(systemName: mode.systemImage)
                    .frame(width: 20)
                Text(mode.displayName)
                Spacer()
                Text(shortcutText(for: mode))
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func shortcutText(for mode: CaptureMode) -> String {
        switch mode {
        case .fullScreen: return "⌘⇧3"
        case .area: return "⌘⇧4"
        case .window: return "⌘⇧5"
        case .ocrText: return "⌘⇧6"
        }
    }
}
