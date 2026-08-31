import AppKit
import InputEngine
import PickerCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator: PickerCoordinator
    private let onboarding = OnboardingWindowController()

    /// Sent by a second copy of the app so the instance that keeps running surfaces its settings.
    private static let openSettingsNotification = Notification.Name("me.bevankay.globalmoji.openSettings")

    override init() {
        do {
            coordinator = try PickerCoordinator(emoji: EmojiCatalog.bundled(), ascii: AsciiCatalog.bundled())
        } catch {
            fatalError("Bundled dataset is missing or corrupt: \(error)")
        }
        super.init()
    }

    func applicationDidFinishLaunching(_: Notification) {
        NSApp.setActivationPolicy(.accessory)
        guard !yieldToRunningInstance() else { return }
        DistributedNotificationCenter.default().addObserver(
            forName: Self.openSettingsNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in AppDelegate.openSettings() }
        }
        startOrOnboard()
    }

    /// Launching an already-running menu bar app has nothing to bring forward, so show settings instead.
    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        Self.openSettings()
        return false
    }

    /// Two copies (e.g. a Debug build and the installed app) would both install event taps.
    /// Hand off to the one already running and quit.
    private func yieldToRunningInstance() -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier else { return false }
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
        guard let existing = others.first else { return false }
        DistributedNotificationCenter.default().postNotificationName(
            Self.openSettingsNotification,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
        existing.activate()
        NSApp.terminate(nil)
        return true
    }

    private static func openSettings() {
        NSApp.activate()
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    func startOrOnboard() {
        if coordinator.start() {
            return
        }
        onboarding.show { [weak self] in
            self?.startOrOnboard()
        }
    }

    func showOnboarding() {
        onboarding.show { [weak self] in
            self?.startOrOnboard()
        }
    }
}
