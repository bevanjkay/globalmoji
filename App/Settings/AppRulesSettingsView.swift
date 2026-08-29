import AppKit
import PickerCore
import SwiftUI

struct AppRulesSettingsView: View {
    @Bindable var store: SettingsStore
    @State private var selection: String?
    @State private var customBundleID = ""

    private var rules: Binding<AppRules> {
        $store.settings.appRules
    }

    var body: some View {
        Form {
            Section {
                Picker("Globalmoji is", selection: rules.mode) {
                    Text("enabled in every app except these").tag(AppRules.Mode.denyList)
                    Text("enabled only in these apps").tag(AppRules.Mode.allowList)
                }
                .pickerStyle(.radioGroup)
            }

            Section {
                List(selection: $selection) {
                    ForEach(rules.wrappedValue.bundleIDs, id: \.self) { bundleID in
                        AppRow(bundleID: bundleID).tag(bundleID)
                    }
                }
                .frame(minHeight: 160)
                HStack {
                    Menu("Add Running App") {
                        ForEach(runningApps, id: \.bundleIdentifier) { app in
                            Button(app.localizedName ?? app.bundleIdentifier ?? "?") {
                                add(app.bundleIdentifier)
                            }
                        }
                    }
                    .fixedSize()
                    TextField("or bundle ID, e.g. com.example.app or com.example.*", text: $customBundleID)
                        .onSubmit { add(customBundleID); customBundleID = "" }
                    Button("Add") { add(customBundleID); customBundleID = "" }
                        .disabled(customBundleID.trimmingCharacters(in: .whitespaces).isEmpty)
                    Button("Remove", role: .destructive) {
                        if let selection {
                            rules.wrappedValue.bundleIDs.removeAll { $0 == selection }
                        }
                        selection = nil
                    }
                    .disabled(selection == nil)
                }
            } footer: {
                Text("A trailing * matches any bundle ID with that prefix.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var runningApps: [NSRunningApplication] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != nil }
            .filter { !rules.wrappedValue.bundleIDs.contains($0.bundleIdentifier ?? "") }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }

    private func add(_ bundleID: String?) {
        guard let bundleID = bundleID?.trimmingCharacters(in: .whitespaces), !bundleID.isEmpty,
              !rules.wrappedValue.bundleIDs.contains(bundleID)
        else { return }
        rules.wrappedValue.bundleIDs.append(bundleID)
    }
}

private struct AppRow: View {
    let bundleID: String

    var body: some View {
        HStack {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .frame(width: 20, height: 20)
                Text(FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: ""))
                Text(bundleID).foregroundStyle(.secondary).font(.caption)
            } else {
                Image(systemName: bundleID.hasSuffix("*") ? "asterisk" : "app.dashed")
                    .frame(width: 20, height: 20)
                    .foregroundStyle(.secondary)
                Text(bundleID)
            }
        }
    }
}
