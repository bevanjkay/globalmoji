import AppKit
import InputEngine
import OSLog
import PickerCore

/// Owns the event tap, trigger controller and inserter; presents the picker UI.
@MainActor
final class PickerCoordinator: TriggerControllerDelegate {
    private let logger = Logger(subsystem: "me.bevankay.globalmoji", category: "picker")
    private let tap = KeyEventTap()
    private let controller = TriggerController()
    private let inserter = TextInserter()
    private var appRules = AppRules()
    private var observers: [NSObjectProtocol] = []

    private(set) var isRunning = false

    init() {
        controller.delegate = self
        tap.onKey = { [controller] event in controller.handle(event) }
        tap.onMouseDown = { [controller] in controller.mouseClicked() }
        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            let bundleID = app?.bundleIdentifier
            MainActor.assumeIsolated { self?.controller.frontmostAppChanged(bundleID: bundleID) }
        })
    }

    func start() -> Bool {
        guard Permissions.allGranted else { return false }
        do {
            try tap.start()
        } catch {
            logger.error("Event tap failed to start: \(error)")
            return false
        }
        controller.frontmostAppChanged(bundleID: NSWorkspace.shared.frontmostApplication?.bundleIdentifier)
        isRunning = true
        return true
    }

    func stop() {
        tap.stop()
        controller.dismiss()
        isRunning = false
    }

    /// Replaces the typed `:query` with `text`.
    func insert(_ text: String) {
        let count = controller.typedLength
        controller.dismiss()
        Task { await inserter.replaceTyped(count: count, with: text) }
    }

    // MARK: - TriggerControllerDelegate

    func triggerController(_: TriggerController, shouldActivateFor bundleID: String?) -> Bool {
        appRules.isEnabled(forBundleID: bundleID)
    }

    func triggerController(_: TriggerController, present query: String) {
        logger.debug("present \(query)")
    }

    func triggerController(_: TriggerController, update query: String) {
        logger.debug("update \(query)")
    }

    func triggerControllerDismiss(_: TriggerController) {
        logger.debug("dismiss")
    }

    func triggerController(_: TriggerController, pickerHandle _: KeyEvent) -> Bool {
        false
    }
}
