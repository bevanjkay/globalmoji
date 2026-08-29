import Foundation

/// Anything the picker can search: emoji, ASCII art, custom images.
public protocol Searchable: Identifiable, Sendable where ID: Hashable & Sendable {
    var searchName: String { get }
    var searchShortcodes: [String] { get }
    var searchKeywords: [String] { get }
}

public struct SearchResult<Item: Searchable>: Sendable {
    public let item: Item
    public let score: Double
}

/// In-memory ranked search. Match tiers (highest first): exact shortcode, shortcode prefix,
/// name prefix, word-in-name prefix, keyword prefix, substring anywhere. Ties fall back to a
/// caller-supplied boost (e.g. recency/frequency) and then dataset order.
public struct SearchIndex<Item: Searchable>: Sendable {
    private struct Entry: Sendable {
        let item: Item
        let name: String
        let nameWords: [String]
        let shortcodes: [String]
        let keywords: [String]
    }

    private let entries: [Entry]

    public init(items: [Item]) {
        entries = items.map { item in
            Entry(
                item: item,
                name: Self.normalize(item.searchName),
                nameWords: Self.normalize(item.searchName).split(separator: " ").map(String.init),
                shortcodes: item.searchShortcodes.map(Self.normalize),
                keywords: item.searchKeywords.map(Self.normalize)
            )
        }
    }

    public var items: [Item] {
        entries.map(\.item)
    }

    public func search(
        _ rawQuery: String,
        limit: Int = 50,
        boost: (Item) -> Double = { _ in 0 }
    ) -> [SearchResult<Item>] {
        let query = Self.normalize(rawQuery)
        guard !query.isEmpty else { return [] }

        var scored: [(index: Int, score: Double)] = []
        scored.reserveCapacity(64)
        for (index, entry) in entries.enumerated() {
            guard let tier = Self.tier(for: query, entry: entry) else { continue }
            scored.append((index, tier + min(max(boost(entry.item), 0), 0.99)))
        }
        scored.sort { lhs, rhs in
            lhs.score != rhs.score ? lhs.score > rhs.score : lhs.index < rhs.index
        }
        return scored.prefix(limit).map { SearchResult(item: entries[$0.index].item, score: $0.score) }
    }

    private static func tier(for query: String, entry: Entry) -> Double? {
        if entry.shortcodes.contains(query) {
            return 100
        }
        if entry.shortcodes.contains(where: { $0.hasPrefix(query) }) {
            return 90
        }
        if entry.name.hasPrefix(query) {
            return 80
        }
        if entry.nameWords.contains(where: { $0.hasPrefix(query) }) {
            return 70
        }
        if entry.keywords.contains(where: { $0.hasPrefix(query) }) {
            return 60
        }
        if entry.name.contains(query) || entry.shortcodes.contains(where: { $0.contains(query) }) {
            return 50
        }
        if entry.keywords.contains(where: { $0.contains(query) }) {
            return 40
        }
        return nil
    }

    static func normalize(_ string: String) -> String {
        string.lowercased()
            .folding(options: [.diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }
}
