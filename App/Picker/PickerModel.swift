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
    var skinTone: SkinTone = .none
    private let maxResults = 64

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
        }
        selectedIndex = 0
    }
}
