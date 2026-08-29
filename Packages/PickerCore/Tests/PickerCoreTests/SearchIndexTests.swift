import PickerCore
import Testing

struct SearchIndexTests {
    static let index: SearchIndex<Emoji> = {
        guard let catalog = try? EmojiCatalog.bundled() else { return SearchIndex(items: []) }
        return SearchIndex(items: catalog.emoji)
    }()

    @Test func exactShortcodeWins() {
        let results = Self.index.search("joy")
        #expect(results.first?.item.character == "😂")
    }

    @Test func shortcodePrefixBeatsKeyword() {
        let results = Self.index.search("thumbs")
        #expect(results.first?.item.id == "1F44D")
        #expect(results.contains { $0.item.id == "1F44E" })
    }

    @Test func namePrefixMatches() {
        let results = Self.index.search("grinning face")
        #expect(results.first?.item.id == "1F600")
    }

    @Test func keywordsMatch() {
        let results = Self.index.search("hello")
        #expect(results.contains { $0.item.character == "👋" })
    }

    @Test func normalisesSeparatorsAndCase() {
        let underscored = Self.index.search("Thumbs_Up").map(\.item.id)
        let hyphenated = Self.index.search("thumbs-up").map(\.item.id)
        #expect(underscored == hyphenated)
        #expect(underscored.first == "1F44D")
    }

    @Test func emptyQueryReturnsNothing() {
        #expect(Self.index.search("  ").isEmpty)
    }

    @Test func boostReordersWithinTier() {
        let plain = Self.index.search("fa").map(\.item.id)
        let boosted = Self.index.search("fa") { $0.id == plain.last ? 0.5 : 0 }.map(\.item.id)
        #expect(boosted.first == plain.last)
    }

    @Test func limitApplies() {
        #expect(Self.index.search("a", limit: 5).count == 5)
    }
}
