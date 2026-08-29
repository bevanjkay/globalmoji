import PickerCore
import Testing

struct AsciiCatalogTests {
    @Test func bundledCatalogLoadsWithUniqueNames() throws {
        let catalog = try AsciiCatalog.bundled()
        #expect(catalog.items.count > 50)
        #expect(Set(catalog.items.map(\.name)).count == catalog.items.count)
        #expect(catalog.items.allSatisfy { !$0.text.isEmpty })
    }

    @Test func searchFindsShrugByNameAndKeyword() throws {
        let index = try SearchIndex(items: AsciiCatalog.bundled().items)
        #expect(index.search("shrug").first?.item.text == "¯\\_(ツ)_/¯")
        #expect(index.search("idk").contains { $0.item.name == "shrug" })
        #expect(index.search("flip").first?.item.name == "table flip")
    }
}
