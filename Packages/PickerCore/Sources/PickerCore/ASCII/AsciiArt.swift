import Foundation

/// A kaomoji or classic text emoticon.
public struct AsciiArt: Codable, Identifiable, Hashable, Sendable {
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

extension AsciiArt: Searchable {
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

public struct AsciiCatalog: Sendable {
    public let items: [AsciiArt]

    public init(items: [AsciiArt]) {
        self.items = items
    }

    public init(data: Data) throws {
        try self.init(items: JSONDecoder().decode([AsciiArt].self, from: data))
    }

    public static func bundled() throws -> AsciiCatalog {
        guard let url = Bundle.module.url(forResource: "ascii", withExtension: "json") else {
            throw EmojiCatalog.CatalogError.missingResource
        }
        return try AsciiCatalog(data: Data(contentsOf: url))
    }
}
