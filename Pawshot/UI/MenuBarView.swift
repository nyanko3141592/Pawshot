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
                    NSApp.activate(ignoringOtherApps: true)
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

            if !coordinator.screenshotHistory.isEmpty {
                Divider()
                    .padding(.vertical, 4)

                HStack {
                    Text("Recent Captures")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        coordinator.clearHistory()
                    } label: {
                        Text("Clear")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 2)

                ForEach(coordinator.screenshotHistory.prefix(5)) { screenshot in
                    historyRow(screenshot: screenshot)
                }
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
        .frame(width: 260)
    }

    private func historyRow(screenshot: Screenshot) -> some View {
        HStack(spacing: 8) {
            let thumbSize = historyThumbnailSize(for: screenshot.image.size)
            Image(nsImage: screenshot.image.resized(to: thumbSize))
                .frame(width: 40, height: 28)
                .background(Color(nsColor: .quaternaryLabelColor))
                .cornerRadius(3)

            VStack(alignment: .leading, spacing: 1) {
                Text(screenshot.captureMode.displayName)
                    .font(.caption)
                    .lineLimit(1)
                Text(historyTimeString(screenshot.capturedAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                ClipboardService.shared.copyToClipboard(screenshot.image)
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 11))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .help("Copy")

            Button {
                coordinator.openEditor(for: screenshot)
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 11))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .help("Edit")

            Button {
                FloatingPreviewService.shared.show(screenshot: screenshot, coordinator: coordinator)
            } label: {
                Image(systemName: "macwindow.badge.plus")
                    .font(.system(size: 11))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .help("Show Preview")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
    }

    private func historyThumbnailSize(for imageSize: NSSize) -> NSSize {
        let maxW: CGFloat = 40
        let maxH: CGFloat = 28
        let scale = min(maxW / max(imageSize.width, 1), maxH / max(imageSize.height, 1), 1.0)
        return NSSize(width: ceil(imageSize.width * scale), height: ceil(imageSize.height * scale))
    }

    private func historyTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "M/d HH:mm"
        }
        return formatter.string(from: date)
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
