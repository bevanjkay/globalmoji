import InputEngine
import SwiftUI

/// Walks the user through granting Accessibility and Input Monitoring.
struct OnboardingView: View {
    @State private var accessibility = Permissions.accessibilityGranted
    @State private var inputMonitoring = Permissions.inputMonitoringGranted
    var onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome to Globalmoji")
                    .font(.title2.bold())
                Text("Type “:” followed by a name in any app to search emoji, GIFs and ASCII faces. "
                    + "Two permissions are needed for that to work.")
                    .foregroundStyle(.secondary)
            }

            permissionRow(
                title: "Input Monitoring",
                detail: "Lets Globalmoji notice when you type the “:” trigger.",
                granted: inputMonitoring,
                request: Permissions.requestInputMonitoring,
                openSettings: Permissions.openInputMonitoringSettings
            )
            permissionRow(
                title: "Accessibility",
                detail: "Lets Globalmoji insert the emoji you pick into the app you’re typing in.",
                granted: accessibility,
                request: Permissions.requestAccessibility,
                openSettings: Permissions.openAccessibilitySettings
            )

            Spacer()
            HStack {
                Text(
                    "Changes here can take a moment to apply. If a permission stays off, toggle it in System Settings."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                Spacer()
                Button("Done", action: onComplete)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!(accessibility && inputMonitoring))
            }
        }
        .padding(24)
        .frame(width: 520, height: 340)
        .task {
            while !Task.isCancelled {
                accessibility = Permissions.accessibilityGranted
                inputMonitoring = Permissions.inputMonitoringGranted
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func permissionRow(
        title: String,
        detail: String,
        granted: Bool,
        request: @escaping () -> Void,
        openSettings: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: granted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(granted ? .green : .secondary)
                .font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail).font(.callout).foregroundStyle(.secondary)
            }
            Spacer()
            if !granted {
                VStack(spacing: 6) {
                    Button("Allow…", action: request)
                    Button("Open Settings", action: openSettings)
                        .buttonStyle(.link)
                        .font(.caption)
                }
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
    }
}
