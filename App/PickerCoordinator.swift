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
    private var observers: [NSObjectProtocol] = []
    private let model: PickerModel
    private let panel: PickerPanel
    let settings: SettingsStore

    private(set) var isRunning = false

    init(emoji: EmojiCatalog, ascii: AsciiCatalog, store: JSONStore = .applicationSupport) {
        settings = SettingsStore(store: store)
        model = PickerModel(emoji: emoji, ascii: ascii, recents: RecentsStore(store: store, file: "recents.json"))
        panel = PickerPanel(model: model)
        settings.onChange = { [weak self] _ in self?.applySettings() }
        applySettings()
        model.onCommit = { [weak self] item in
            guard let self else { return }
            if case let .gif(gif) = item {
                insert(gif: gif)
            } else {
                insert(item.insertionText(skinTone: model.skinTone))
            }
        }
        controller.delegate = self
        tap.onKey = { [controller] event in controller.handle(event) }
        tap.onMouseDown = { [weak self] in
            guard let self, !panel.contains(screenPoint: NSEvent.mouseLocation) else { return }
            controller.mouseClicked()
        }
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

    /// Replaces the typed `:query` with the GIF as image data, falling back to its URL.
    func insert(gif: GIF) {
        let count = controller.typedLength
        controller.dismiss()
        Task {
            await inserter.deleteBackward(count: count)
            if let data = await GIFImageCache.shared.data(for: gif.fullURL) {
                await inserter.paste(
                    imageData: data,
                    type: NSPasteboard.PasteboardType("com.compuserve.gif"),
                    fallbackURL: gif.fullURL
                )
            } else {
                await inserter.insert(gif.fullURL.absoluteString)
            }
        }
    }

    private var bundledGiphyKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "GiphyAPIKey") as? String) ?? ""
    }

    private func applySettings() {
        let current = settings.settings
        model.skinTone = current.skinTone
        let giphyKey = current.giphyAPIKey.isEmpty ? bundledGiphyKey : current.giphyAPIKey
        if (model.gifProvider as? GiphyProvider)?.apiKey != giphyKey {
            model.gifProvider = giphyKey.isEmpty ? nil : GiphyProvider(apiKey: giphyKey)
        }
        inserter.strategy = current.insertionStrategy == .paste ? .paste : .type
        let configuration = TriggerStateMachine.Configuration(
            trigger: current.triggerCharacter,
            minimumCharacters: current.minimumCharacters
        )
        if configuration.trigger != controller.configuration.trigger
            || configuration.minimumCharacters != controller.configuration.minimumCharacters
        {
            controller.configuration = configuration
        }
        controller.frontmostAppChanged(bundleID: controller.frontmostBundleID)
    }

    // MARK: - TriggerControllerDelegate

    func triggerController(_: TriggerController, shouldActivateFor bundleID: String?) -> Bool {
        settings.settings.appRules.isEnabled(forBundleID: bundleID)
    }

    func triggerController(_: TriggerController, present query: String) {
        model.update(query: query)
        panel.present(at: CaretLocator.anchorPoint())
    }

    func triggerController(_: TriggerController, update query: String) {
        model.update(query: query)
    }

    func triggerControllerDismiss(_: TriggerController) {
        panel.dismiss()
    }

    func triggerController(_: TriggerController, pickerHandle event: KeyEvent) -> Bool {
        model.handle(event)
    }
}
