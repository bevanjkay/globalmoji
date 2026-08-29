import InputEngine
import Observation
import PickerCore

@MainActor
@Observable
final class PickerModel {
    private(set) var query = ""
    private(set) var items: [PickerItem] = []
    private(set) var selectedIndex = 0
    var skinTone: SkinTone = .none
    let columns = 8
    private let maxResults = 64

    private let index: SearchIndex<Emoji>
    private let recents: RecentsStore
    var onCommit: ((PickerItem) -> Void)?

    init(catalog: EmojiCatalog, recents: RecentsStore) {
        index = SearchIndex(items: catalog.emoji)
        self.recents = recents
    }

    var selectedItem: PickerItem? {
        items.indices.contains(selectedIndex) ? items[selectedIndex] : nil
    }

    func update(query: String) {
        self.query = query
        let recents = recents.recents
        items = index.search(query, limit: maxResults) { recents.boost(for: $0.id) }
            .map { .emoji($0.item) }
        selectedIndex = 0
    }

    func select(_ item: PickerItem) {
        if let index = items.firstIndex(of: item) {
            selectedIndex = index
        }
    }

    func commit(_ item: PickerItem? = nil) {
        guard let item = item ?? selectedItem else { return }
        if case let .emoji(emoji) = item {
            recents.record(emoji.id)
        }
        onCommit?(item)
    }

    /// Returns `true` if the key was consumed.
    func handle(_ event: KeyEvent) -> Bool {
        guard !items.isEmpty else { return event.key == .enter || event.key == .tab }
        switch event.key {
        case .enter, .tab:
            commit()
        case .left:
            selectedIndex = max(selectedIndex - 1, 0)
        case .right:
            selectedIndex = min(selectedIndex + 1, items.count - 1)
        case .up:
            selectedIndex = max(selectedIndex - columns, 0)
        case .down:
            selectedIndex = selectedIndex + columns < items.count ? selectedIndex + columns : items.count - 1
        default:
            return false
        }
        return true
    }
}
