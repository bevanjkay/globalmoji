import SwiftUI

/// SwiftUI owns the Settings scene and only vends `openSettings` through a view's
/// environment, so the menu bar label stashes it where AppKit callers can reach it.
/// The AppKit route (`showSettingsWindow:`) is silently a no-op for this app.
@MainActor
enum SettingsWindow {
    static var open: (() -> Void)?

    static func show() {
        open?()
        DispatchQueue.main.async { NSApp.activate(ignoringOtherApps: true) }
    }
}

private struct MenuBarLabel: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Image(systemName: "face.smiling")
            .accessibilityLabel("Globalmoji")
            .onAppear { SettingsWindow.open = { openSettings() } }
    }
}

@main
struct GlobalmojiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarMenu(appDelegate: appDelegate)
        } label: {
            MenuBarLabel()
        }
        Settings {
            SettingsView(store: appDelegate.coordinator.settings)
        }
    }
}
