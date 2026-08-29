import AppKit
import InputEngine
import PickerCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator: PickerCoordinator
    private let onboarding = OnboardingWindowController()

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
        startOrOnboard()
    }

    /// Two copies (e.g. a Debug build and the installed app) would both install event taps.
    /// Hand off to the one already running and quit.
    private func yieldToRunningInstance() -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier else { return false }
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
        guard let existing = others.first else { return false }
        existing.activate()
        NSApp.terminate(nil)
        return true
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
