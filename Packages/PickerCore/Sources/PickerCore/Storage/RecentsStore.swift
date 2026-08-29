import Foundation

/// Most-recently-used items per mode, with use counts for search boosting.
public struct Recents: Codable, Equatable, Sendable {
    public struct Entry: Codable, Equatable, Sendable {
        public var id: String
        public var count: Int
        public var lastUsed: Date
    }

    public var entries: [Entry] = []
    public var limit = 40

    public init() {}

    public mutating func record(_ id: String, at date: Date = .now) {
        if let index = entries.firstIndex(where: { $0.id == id }) {
            var entry = entries.remove(at: index)
            entry.count += 1
            entry.lastUsed = date
            entries.insert(entry, at: 0)
        } else {
            entries.insert(Entry(id: id, count: 1, lastUsed: date), at: 0)
        }
        if entries.count > limit {
            entries.removeLast(entries.count - limit)
        }
    }

    public var ids: [String] {
        entries.map(\.id)
    }

    /// 0..<1 boost for `SearchIndex`: recency-ordered, most recent highest.
    public func boost(for id: String) -> Double {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return 0 }
        return 0.9 * (1 - Double(index) / Double(max(entries.count, 1)))
    }
}

@MainActor
public final class RecentsStore {
    private let store: JSONStore
    private let file: String
    public private(set) var recents: Recents

    public init(store: JSONStore, file: String) {
        self.store = store
        self.file = file
        recents = store.load(Recents.self, from: file) ?? Recents()
    }

    public func record(_ id: String) {
        recents.record(id)
        try? store.save(recents, to: file)
    }
}
