import SwiftUI

struct MenuBarMenu: View {
    @Environment(\.openSettings) private var openSettings
    let appDelegate: AppDelegate

    var body: some View {
        Button("Settings…") {
            openSettings()
            NSApp.activate()
        }
        .keyboardShortcut(",")
        Button("Permissions…") {
            appDelegate.showOnboarding()
        }
        Divider()
        Button("Quit Globalmoji") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
