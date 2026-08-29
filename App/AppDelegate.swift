import AppKit
import InputEngine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator = PickerCoordinator()
    private let onboarding = OnboardingWindowController()

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
