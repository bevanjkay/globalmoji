import SwiftUI

@main
struct GlobalmojiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Globalmoji", systemImage: "face.smiling") {
            MenuBarMenu(appDelegate: appDelegate)
        }
        Settings {
            SettingsView()
        }
    }
}
