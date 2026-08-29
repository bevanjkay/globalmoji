import Foundation

/// Tiny Codable-to-file persistence used for settings, recents and favourites.
public struct JSONStore: Sendable {
    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    /// `~/Library/Application Support/Globalmoji`.
    public static var applicationSupport: JSONStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return JSONStore(directory: base.appending(path: "Globalmoji", directoryHint: .isDirectory))
    }

    public func load<T: Decodable>(_ type: T.Type, from file: String) -> T? {
        let url = directory.appending(path: file)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    public func save(_ value: some Encodable, to file: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(value).write(to: directory.appending(path: file), options: .atomic)
    }
}
