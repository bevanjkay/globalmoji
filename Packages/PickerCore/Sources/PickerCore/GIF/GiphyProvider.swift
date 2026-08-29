import Foundation

/// GIPHY REST API client. Keys are free at https://developers.giphy.com.
public struct GiphyProvider: GIFProvider {
    public let name = "GIPHY"
    public let apiKey: String
    public var rating = "pg-13"
    private let session: URLSession

    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    public func search(query: String, limit: Int = 24, offset: Int = 0) async throws -> [GIF] {
        try await fetch(path: "search", query: [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ])
    }

    public func trending(limit: Int = 24) async throws -> [GIF] {
        try await fetch(path: "trending", query: [URLQueryItem(name: "limit", value: String(limit))])
    }

    private func fetch(path: String, query: [URLQueryItem]) async throws -> [GIF] {
        guard !apiKey.isEmpty else { throw GIFProviderError.missingAPIKey }
        var components = URLComponents(string: "https://api.giphy.com/v1/gifs/\(path)")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "rating", value: rating),
        ] + query
        let (data, response) = try await session.data(from: components.url!)
        if let http = response as? HTTPURLResponse, !(200 ..< 300).contains(http.statusCode) {
            throw GIFProviderError.httpStatus(http.statusCode)
        }
        return try Self.parse(data)
    }

    /// Decodes a GIPHY gifs response into `GIF`s, skipping entries without usable renditions.
    public static func parse(_ data: Data) throws -> [GIF] {
        let response: Response
        do {
            response = try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw GIFProviderError.invalidResponse
        }
        return response.data.compactMap { item in
            guard let preview = item.images.fixedWidthSmall ?? item.images.previewGif,
                  let previewURL = URL(string: preview.url),
                  let fullURL = URL(string: item.images.original.url)
            else { return nil }
            return GIF(
                id: item.id,
                title: item.title,
                previewURL: previewURL,
                fullURL: fullURL,
                width: Int(preview.width) ?? 100,
                height: Int(preview.height) ?? 100
            )
        }
    }

    private struct Response: Decodable {
        let data: [Item]
    }

    private struct Item: Decodable {
        let id: String
        let title: String
        let images: Images
    }

    private struct Images: Decodable {
        let original: Rendition
        let fixedWidthSmall: Rendition?
        let previewGif: Rendition?

        private enum CodingKeys: String, CodingKey {
            case original
            case fixedWidthSmall = "fixed_width_small"
            case previewGif = "preview_gif"
        }
    }

    private struct Rendition: Decodable {
        let url: String
        let width: String
        let height: String
    }
}
