import Foundation

public struct GIF: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    /// Small animated preview suitable for the picker grid.
    public let previewURL: URL
    /// Full-size animated GIF to insert.
    public let fullURL: URL
    public let width: Int
    public let height: Int

    public init(id: String, title: String, previewURL: URL, fullURL: URL, width: Int, height: Int) {
        self.id = id
        self.title = title
        self.previewURL = previewURL
        self.fullURL = fullURL
        self.width = width
        self.height = height
    }
}

public protocol GIFProvider: Sendable {
    var name: String { get }
    func search(query: String, limit: Int, offset: Int) async throws -> [GIF]
    func trending(limit: Int) async throws -> [GIF]
}

public enum GIFProviderError: Error, Equatable {
    case missingAPIKey
    case httpStatus(Int)
    case invalidResponse
}
