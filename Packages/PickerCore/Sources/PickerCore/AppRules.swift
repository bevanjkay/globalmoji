import Foundation

/// Decides whether the picker is active for a given frontmost application.
public struct AppRules: Codable, Equatable, Sendable {
    public enum Mode: String, Codable, Sendable {
        /// Enabled everywhere except listed bundle IDs.
        case denyList
        /// Disabled everywhere except listed bundle IDs.
        case allowList
    }

    public var mode: Mode
    /// Bundle identifiers; a trailing `*` matches a prefix (e.g. `com.1password.*`).
    public var bundleIDs: [String]

    public static let defaultDenyList = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "com.1password.*",
        "com.bitwarden.desktop",
    ]

    public init(mode: Mode = .denyList, bundleIDs: [String] = AppRules.defaultDenyList) {
        self.mode = mode
        self.bundleIDs = bundleIDs
    }

    public func isEnabled(forBundleID bundleID: String?) -> Bool {
        guard let bundleID else { return mode == .denyList }
        let listed = bundleIDs.contains { pattern in
            if pattern.hasSuffix("*") {
                return bundleID.hasPrefix(pattern.dropLast())
            }
            return pattern == bundleID
        }
        switch mode {
        case .denyList: return !listed
        case .allowList: return listed
        }
    }
}
