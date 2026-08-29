import Foundation

/// The bundled emoji dataset, ordered by Unicode CLDR presentation order.
public struct EmojiCatalog: Sendable {
    public let source: String
    public let emoji: [Emoji]
    private let byID: [String: Emoji]
    private let byShortcode: [String: Emoji]

    public init(source: String, emoji: [Emoji]) {
        self.source = source
        self.emoji = emoji
        byID = Dictionary(emoji.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        byShortcode = Dictionary(
            emoji.flatMap { item in item.shortcodes.map { ($0, item) } },
            uniquingKeysWith: { first, _ in first }
        )
    }

    public init(data: Data) throws {
        let file = try JSONDecoder().decode(File.self, from: data)
        self.init(source: file.source, emoji: file.emoji)
    }

    /// Loads the dataset bundled with the package.
    public static func bundled() throws -> EmojiCatalog {
        guard let url = Bundle.module.url(forResource: "emoji", withExtension: "json") else {
            throw CatalogError.missingResource
        }
        return try EmojiCatalog(data: Data(contentsOf: url))
    }

    public func emoji(id: String) -> Emoji? {
        byID[id]
    }

    public func emoji(shortcode: String) -> Emoji? {
        byShortcode[shortcode]
    }

    public func emoji(in group: EmojiGroup) -> [Emoji] {
        emoji.filter { $0.group == group }
    }

    public enum CatalogError: Error {
        case missingResource
    }

    private struct File: Decodable {
        let source: String
        let emoji: [Emoji]
    }
}
