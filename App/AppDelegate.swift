import AppKit
import InputEngine
import PickerCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator: PickerCoordinator
    private let onboarding = OnboardingWindowController()

    override init() {
        do {
            coordinator = try PickerCoordinator(catalog: EmojiCatalog.bundled())
        } catch {
            fatalError("Bundled emoji dataset is missing or corrupt: \(error)")
        }
        super.init()
    }

    func applicationDidFinishLaunching(_: Notification) {
        NSApp.setActivationPolicy(.accessory)
        startOrOnboard()
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
