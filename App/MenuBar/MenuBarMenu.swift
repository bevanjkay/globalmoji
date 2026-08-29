import SwiftUI

struct MenuBarMenu: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Settings…") {
            openSettings()
            NSApp.activate()
        }
        .keyboardShortcut(",")
        Divider()
        Button("Quit Globalmoji") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
