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

    private static func open(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
