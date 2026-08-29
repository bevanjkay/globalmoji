import PickerCore

enum PickerMode: Int, CaseIterable {
    case emoji
    case gif
    case ascii

    var title: String {
        switch self {
        case .emoji: "Emoji"
        case .gif: "GIF"
        case .ascii: "ASCII"
        }
    }

    var next: PickerMode {
        PickerMode.allCases[(rawValue + 1) % PickerMode.allCases.count]
    }

    var previous: PickerMode {
        PickerMode.allCases[(rawValue + PickerMode.allCases.count - 1) % PickerMode.allCases.count]
    }
}

/// Anything the picker can display and insert.
enum PickerItem: Identifiable, Hashable {
    case emoji(Emoji)
    case ascii(AsciiArt)

    var id: String {
        switch self {
        case let .emoji(emoji): "emoji:\(emoji.id)"
        case let .ascii(art): "ascii:\(art.id)"
        }
    }

    var title: String {
        switch self {
        case let .emoji(emoji): emoji.name
        case let .ascii(art): art.name
        }
    }

    var subtitle: String? {
        switch self {
        case let .emoji(emoji): emoji.shortcodes.first.map { ":\($0):" }
        case .ascii: nil
        }
    }

    func insertionText(skinTone: SkinTone) -> String {
        switch self {
        case let .emoji(emoji): emoji.character(with: skinTone)
        case let .ascii(art): art.text
        }
    }
}
