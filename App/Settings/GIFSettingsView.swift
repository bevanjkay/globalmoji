import PickerCore
import SwiftUI

struct GIFSettingsView: View {
    @Bindable var store: SettingsStore

    private var bundledKeyPresent: Bool {
        !((Bundle.main.object(forInfoDictionaryKey: "GiphyAPIKey") as? String) ?? "").isEmpty
    }

    var body: some View {
        Form {
            Section("GIPHY") {
                TextField(
                    "API key",
                    text: $store.settings.giphyAPIKey,
                    prompt: Text(bundledKeyPresent ? "Using built-in key" : "Paste your GIPHY API key")
                )
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                Text(bundledKeyPresent
                    ? "This build includes a shared key. Add your own to avoid its rate limits."
                    :
                    "This build has no built-in key. Create a free app at developers.giphy.com and paste its key here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Link("Get a GIPHY API key", destination: URL(string: "https://developers.giphy.com/dashboard/")!)
                    .font(.caption)
            }
            Section("Inserting GIFs") {
                Text(
                    "GIFs are pasted as image data with the link as a fallback. Slack and Discord accept the image; "
                        + "apps that only take plain text receive the link."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
