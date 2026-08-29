import Foundation
import Observation

public enum InsertionStrategy: String, Codable, CaseIterable, Sendable {
    case paste
    case type

    public var title: String {
        switch self {
        case .paste: "Paste (most compatible)"
        case .type: "Type characters (leaves clipboard alone)"
        }
    }
}

public struct Settings: Codable, Equatable, Sendable {
    public var trigger: String = ":"
    public var minimumCharacters: Int = 2
    public var skinTone: SkinTone = .none
    public var insertionStrategy: InsertionStrategy = .paste
    public var appRules: AppRules = .init()
    public var giphyAPIKey: String = ""

    public init() {}

    public var triggerCharacter: Character {
        trigger.first ?? ":"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Settings()
        trigger = try container.decodeIfPresent(String.self, forKey: .trigger) ?? defaults.trigger
        minimumCharacters = try container.decodeIfPresent(Int.self, forKey: .minimumCharacters)
            ?? defaults.minimumCharacters
        skinTone = try container.decodeIfPresent(SkinTone.self, forKey: .skinTone) ?? defaults.skinTone
        insertionStrategy = try container.decodeIfPresent(InsertionStrategy.self, forKey: .insertionStrategy)
            ?? defaults.insertionStrategy
        appRules = try container.decodeIfPresent(AppRules.self, forKey: .appRules) ?? defaults.appRules
        giphyAPIKey = try container.decodeIfPresent(String.self, forKey: .giphyAPIKey) ?? defaults.giphyAPIKey
    }
}

/// Observable, autosaving settings. Views bind to `settings`; the coordinator observes `onChange`.
@MainActor
@Observable
public final class SettingsStore {
    public var settings: Settings {
        didSet {
            guard settings != oldValue else { return }
            try? store.save(settings, to: file)
            onChange?(settings)
        }
    }

    @ObservationIgnored public var onChange: ((Settings) -> Void)?
    @ObservationIgnored private let store: JSONStore
    @ObservationIgnored private let file: String

    public init(store: JSONStore, file: String = "settings.json") {
        self.store = store
        self.file = file
        settings = store.load(Settings.self, from: file) ?? Settings()
    }
}
