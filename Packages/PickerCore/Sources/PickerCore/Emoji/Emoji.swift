import Foundation

public enum EmojiGroup: Int, Codable, CaseIterable, Sendable {
    case smileysAndEmotion = 0
    case peopleAndBody = 1
    case animalsAndNature = 3
    case foodAndDrink = 4
    case travelAndPlaces = 5
    case activities = 6
    case objects = 7
    case symbols = 8
    case flags = 9

    public var title: String {
        switch self {
        case .smileysAndEmotion: "Smileys & Emotion"
        case .peopleAndBody: "People & Body"
        case .animalsAndNature: "Animals & Nature"
        case .foodAndDrink: "Food & Drink"
        case .travelAndPlaces: "Travel & Places"
        case .activities: "Activities"
        case .objects: "Objects"
        case .symbols: "Symbols"
        case .flags: "Flags"
        }
    }
}

public enum SkinTone: Int, Codable, CaseIterable, Sendable {
    case none = 0
    case light = 1
    case mediumLight = 2
    case medium = 3
    case mediumDark = 4
    case dark = 5

    public var title: String {
        switch self {
        case .none: "Default"
        case .light: "Light"
        case .mediumLight: "Medium-Light"
        case .medium: "Medium"
        case .mediumDark: "Medium-Dark"
        case .dark: "Dark"
        }
    }
}

public struct Emoji: Codable, Identifiable, Hashable, Sendable {
    /// Unicode hexcode, e.g. `1F44B`. Stable identifier across dataset versions.
    public let id: String
    public let character: String
    public let name: String
    public let group: EmojiGroup
    public let order: Int
    public let unicodeVersion: Double
    public let keywords: [String]
    public let shortcodes: [String]
    public let emoticons: [String]
    /// Skin-tone variants indexed by `SkinTone.rawValue - 1`; empty when unsupported.
    public let skinVariants: [String]

    public var supportsSkinTones: Bool {
        !skinVariants.isEmpty
    }

    public func character(with tone: SkinTone) -> String {
        guard tone != .none, skinVariants.count == 5 else { return character }
        return skinVariants[tone.rawValue - 1]
    }

    private enum CodingKeys: String, CodingKey {
        case id = "h"
        case character = "e"
        case name = "n"
        case group = "g"
        case order = "o"
        case unicodeVersion = "v"
        case keywords = "k"
        case shortcodes = "s"
        case emoticons = "m"
        case skinVariants = "t"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        character = try container.decode(String.self, forKey: .character)
        name = try container.decode(String.self, forKey: .name)
        group = try container.decode(EmojiGroup.self, forKey: .group)
        order = try container.decode(Int.self, forKey: .order)
        unicodeVersion = try container.decode(Double.self, forKey: .unicodeVersion)
        keywords = try container.decodeIfPresent([String].self, forKey: .keywords) ?? []
        shortcodes = try container.decodeIfPresent([String].self, forKey: .shortcodes) ?? []
        emoticons = try container.decodeIfPresent([String].self, forKey: .emoticons) ?? []
        skinVariants = try container.decodeIfPresent([String].self, forKey: .skinVariants) ?? []
    }

    public init(
        id: String,
        character: String,
        name: String,
        group: EmojiGroup,
        order: Int,
        unicodeVersion: Double = 1,
        keywords: [String] = [],
        shortcodes: [String] = [],
        emoticons: [String] = [],
        skinVariants: [String] = []
    ) {
        self.id = id
        self.character = character
        self.name = name
        self.group = group
        self.order = order
        self.unicodeVersion = unicodeVersion
        self.keywords = keywords
        self.shortcodes = shortcodes
        self.emoticons = emoticons
        self.skinVariants = skinVariants
    }
}

extension Emoji: Searchable {
    public var searchName: String {
        name
    }

    public var searchShortcodes: [String] {
        shortcodes
    }

    public var searchKeywords: [String] {
        keywords
    }
}
