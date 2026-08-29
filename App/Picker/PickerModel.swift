import InputEngine
import Observation
import PickerCore

@MainActor
@Observable
final class PickerModel {
    private(set) var query = ""
    private(set) var mode: PickerMode = .emoji
    private(set) var items: [PickerItem] = []
    private(set) var selectedIndex = 0
    private(set) var isLoadingGIFs = false
    private(set) var gifError: String?
    var skinTone: SkinTone = .none
    var gifProvider: GIFProvider? {
        didSet {
            if mode == .gif {
                refresh()
            }
        }
    }

    private let maxResults = 64
    private var gifTask: Task<Void, Never>?

    private let emojiIndex: SearchIndex<Emoji>
    private let asciiIndex: SearchIndex<AsciiArt>
    private let recents: RecentsStore
    var onCommit: ((PickerItem) -> Void)?

    init(emoji: EmojiCatalog, ascii: AsciiCatalog, recents: RecentsStore) {
        emojiIndex = SearchIndex(items: emoji.emoji)
        asciiIndex = SearchIndex(items: ascii.items)
        self.recents = recents
    }

    /// Grid width for the current mode; text results are a single column.
    var columns: Int {
        switch mode {
        case .emoji: 8
        case .gif: 3
        case .ascii: 1
        }
    }

    var selectedItem: PickerItem? {
        items.indices.contains(selectedIndex) ? items[selectedIndex] : nil
    }

    func update(query: String) {
        self.query = query
        refresh()
    }

    func setMode(_ mode: PickerMode) {
        guard mode != self.mode else { return }
        self.mode = mode
        refresh()
    }

    func select(_ item: PickerItem) {
        if let index = items.firstIndex(of: item) {
            selectedIndex = index
        }
    }

    func commit(_ item: PickerItem? = nil) {
        guard let item = item ?? selectedItem else { return }
        recents.record(item.id)
        onCommit?(item)
    }

    /// Returns `true` if the key was consumed.
    func handle(_ event: KeyEvent) -> Bool {
        switch event.key {
        case .tab:
            setMode(event.modifiers.contains(.shift) ? mode.previous : mode.next)
            return true
        case .enter:
            commit()
            return true
        case .left:
            selectedIndex = max(selectedIndex - 1, 0)
        case .right:
            selectedIndex = min(selectedIndex + 1, max(items.count - 1, 0))
        case .up:
            selectedIndex = max(selectedIndex - columns, 0)
        case .down:
            selectedIndex = selectedIndex + columns < items.count ? selectedIndex + columns : max(items.count - 1, 0)
        default:
            return false
        }
        return true
    }

    private func refresh() {
        let recents = recents.recents
        switch mode {
        case .emoji:
            items = emojiIndex.search(query, limit: maxResults) { recents.boost(for: "emoji:\($0.id)") }
                .map { .emoji($0.item) }
        case .ascii:
            items = asciiIndex.search(query, limit: maxResults) { recents.boost(for: "ascii:\($0.id)") }
                .map { .ascii($0.item) }
        case .gif:
            items = []
            searchGIFs()
        }
        selectedIndex = 0
    }

    private func searchGIFs() {
        gifTask?.cancel()
        gifError = nil
        guard let provider = gifProvider else {
            isLoadingGIFs = false
            gifError = "Add a GIPHY API key in Settings › GIFs to search GIFs."
            return
        }
        isLoadingGIFs = true
        let query = query
        gifTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            do {
                let gifs = try await provider.search(query: query, limit: 24, offset: 0)
                guard !Task.isCancelled, let self, mode == .gif, self.query == query else { return }
                items = gifs.map { .gif($0) }
                selectedIndex = 0
                isLoadingGIFs = false
            } catch is CancellationError {
            } catch {
                guard !Task.isCancelled, let self else { return }
                isLoadingGIFs = false
                gifError = Self.describe(error)
            }
        }
    }

    private static func describe(_ error: Error) -> String {
        switch error {
        case GIFProviderError.missingAPIKey: "Add a GIPHY API key in Settings › GIFs."
        case GIFProviderError.httpStatus(401), GIFProviderError.httpStatus(403): "GIPHY rejected the API key."
        case GIFProviderError.httpStatus(429): "GIPHY rate limit reached. Try again shortly."
        case let GIFProviderError.httpStatus(code): "GIPHY returned HTTP \(code)."
        default: "Couldn't reach GIPHY."
        }
    }
}
