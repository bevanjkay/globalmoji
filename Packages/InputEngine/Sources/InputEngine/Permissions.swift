import AppKit
import ApplicationServices

/// Accessibility (text insertion, caret lookup) and Input Monitoring (event tap) permissions.
public enum Permissions {
    public static var accessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    public static var inputMonitoringGranted: Bool {
        CGPreflightListenEventAccess()
    }

    public static var allGranted: Bool {
        accessibilityGranted && inputMonitoringGranted
    }

    /// Triggers the system prompt (and adds the app to the list in System Settings).
    public static func requestAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    public static func requestInputMonitoring() {
        _ = CGRequestListenEventAccess()
    }

    public static func openAccessibilitySettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    public static func openInputMonitoringSettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
    }

    /// Clears this app's Accessibility and Input Monitoring grants so macOS prompts again.
    ///
    /// TCC pins a grant to the code signature of the binary that requested it. Ad-hoc signed builds get a
    /// new hash on every build, so after an update System Settings can show the toggles on while the running
    /// binary is still denied. Resetting is the only way out short of a stable signing identity.
    @discardableResult
    public static func resetGrants(bundleID: String? = Bundle.main.bundleIdentifier) -> Bool {
        guard let bundleID else { return false }
        var succeeded = true
        for service in ["Accessibility", "ListenEvent"] {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
            process.arguments = ["reset", service, bundleID]
            process.standardOutput = nil
            process.standardError = nil
            do {
                try process.run()
                process.waitUntilExit()
                succeeded = succeeded && process.terminationStatus == 0
            } catch {
                succeeded = false
            }
        }
        return succeeded
    }

    /// Relaunches the app; Input Monitoring in particular is often only honoured by a fresh process.
    public static func relaunch() {
        let url = Bundle.main.bundleURL
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, _ in
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
    }

    private static func open(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
