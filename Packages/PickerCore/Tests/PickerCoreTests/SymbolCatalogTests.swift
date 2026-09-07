import PickerCore
import Testing

struct SymbolCatalogTests {
    @Test func bundledCatalogLoadsWithUniqueNames() throws {
        let catalog = try SymbolCatalog.bundled()
        #expect(catalog.items.count > 100)
        #expect(Set(catalog.items.map(\.name)).count == catalog.items.count)
        #expect(catalog.items.allSatisfy { !$0.text.isEmpty })
    }

    @Test func searchFindsSymbolsByNameAndKeyword() throws {
        let index = try SearchIndex(items: SymbolCatalog.bundled().items)
        #expect(index.search("arrow").first?.item.text == "→")
        #expect(index.search("cmd").first?.item.text == "⌘")
        #expect(index.search("check").first?.item.text == "✓")
        #expect(index.search("degree").contains { $0.item.text == "°" })
        #expect(index.search("copyright").first?.item.text == "©")
    }
}
