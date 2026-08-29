import PickerCore
import ServiceManagement
import SwiftUI

struct GeneralSettingsView: View {
    @Bindable var store: SettingsStore
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var launchAtLoginError: String?

    var body: some View {
        Form {
            Section("Trigger") {
                Picker("Trigger key", selection: $store.settings.trigger) {
                    ForEach([":", ";", "/", "\\", "`"], id: \.self) { key in
                        Text(key).font(.system(.body, design: .monospaced)).tag(key)
                    }
                }
                Stepper(value: $store.settings.minimumCharacters, in: 1 ... 5) {
                    Text("Show picker after ^[\(store.settings.minimumCharacters) character](inflect: true)")
                }
                Text("Type \(store.settings.trigger)smile in any text field to search.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Emoji") {
                Picker("Skin tone", selection: $store.settings.skinTone) {
                    ForEach(SkinTone.allCases, id: \.self) { tone in
                        Text("\(sample.character(with: tone)) \(tone.title)").tag(tone)
                    }
                }
            }

            Section("Insertion") {
                Picker("Insert using", selection: $store.settings.insertionStrategy) {
                    ForEach(InsertionStrategy.allCases, id: \.self) { strategy in
                        Text(strategy.title).tag(strategy)
                    }
                }
                Text("Paste restores your previous clipboard contents afterwards. "
                    + "Typing avoids the clipboard but a few apps drop characters.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Startup") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
                if let launchAtLoginError {
                    Text(launchAtLoginError).font(.caption).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var sample: Emoji {
        Emoji(
            id: "1F44B",
            character: "👋",
            name: "waving hand",
            group: .peopleAndBody,
            order: 0,
            skinVariants: ["👋🏻", "👋🏼", "👋🏽", "👋🏾", "👋🏿"]
        )
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = error.localizedDescription
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
