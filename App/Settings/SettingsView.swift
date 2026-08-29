import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Text("Globalmoji settings will appear here.")
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 320)
    }
}
