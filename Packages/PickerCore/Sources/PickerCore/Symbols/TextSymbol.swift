import Foundation

/// A Unicode symbol that is awkward to type: arrows, maths, currency, Mac key glyphs.
public struct TextSymbol: Codable, Identifiable, Hashable, Sendable {
    public let name: String
    public let text: String
    public let keywords: [String]

    /// Stable identifier derived from the name (names are unique in the dataset).
    public var id: String {
        name
    }

    public init(name: String, text: String, keywords: [String] = []) {
        self.name = name
        self.text = text
        self.keywords = keywords
    }

    private enum CodingKeys: String, CodingKey {
        case name = "n"
        case text = "t"
        case keywords = "k"
    }
}

extension TextSymbol: Searchable {
    public var searchName: String {
        name
    }

    public var searchShortcodes: [String] {
        []
    }

    public var searchKeywords: [String] {
        keywords
    }
}

public struct SymbolCatalog: Sendable {
    public let items: [TextSymbol]

    public init(items: [TextSymbol]) {
        self.items = items
    }

    public init(data: Data) throws {
        try self.init(items: JSONDecoder().decode([TextSymbol].self, from: data))
    }

    public static func bundled() throws -> SymbolCatalog {
        guard let url = Bundle.module.url(forResource: "symbols", withExtension: "json") else {
            throw EmojiCatalog.CatalogError.missingResource
        }
        return try SymbolCatalog(data: Data(contentsOf: url))
    }
}
